import json
import logging
import os
import gzip
import time

import boto3
import psycopg2
import pandas as pd
from io import BytesIO, TextIOWrapper

LOGGER = logging.getLogger()
LOGGER.setLevel(logging.INFO)

HOST = "host"
DB_NAME = "database_name"
USR_NAME = "user_name"
PASSWORD = "password"
TARGET_SQS_URL = "rs_loader_sqs_url"
STAGING_BUCKET = "staging_bucket"
SRC_BUCKET = "src_bucket"
CFG_FILE_PATH = "./cfg.csv"
CFG_RS_TABLE = "rs_table"
MAP_FIELD = "report_type"
LOOKUP_COL = "output_id"
REQUIRED_COLS = [LOOKUP_COL, MAP_FIELD]
COLS_DTYPES = {
    "groupinghierarchy": "varchar(max)", 
    "symbol": "varchar(max)", 
    LOOKUP_COL: "varchar(max)", 
    "acct": "varchar(max)", 
    "period": "varchar(max)", 
    "report_curr": "varchar(max)", 
    "end_date": "varchar(max)",
    "ac_secmast_id": "varchar(max)"
}
DELIMITER = "|"
CHUNK_SIZE = 100000
DELETE_BATCH_SIZE = 50
MAX_SCHEMA_MISSING_RETRIES = 3
MISSING_SCHEMA_WAIT_TIME = 60


def lambda_handler(event, context):
    LOGGER.info(f"Starting data_transformer process...")
    host = os.getenv(HOST)
    dbname = os.getenv(DB_NAME)
    user_name = os.getenv(USR_NAME)
    password = os.getenv(PASSWORD)
    target_sqs_url = os.getenv(TARGET_SQS_URL)
    staging_bucket = os.getenv(STAGING_BUCKET)
    src_bucket = os.getenv(SRC_BUCKET)
    """
    ------------------------------------------------------------------------------------------------
    SECTION 1: GET DATA
    ------------------------------------------------------------------------------------------------
    """
    # get cfg file in dataframe format
    try:
        cfg = _get_data(CFG_FILE_PATH)
    except Exception as e:
        LOGGER.error(f"Unable to get the cfg file from {CFG_FILE_PATH}. Please check the path.")
    
    s3 = boto3.resource("s3")
    sqs = boto3.client("sqs")

    for record in event["Records"]:
        # get FactSet S3 path from the record
        body = json.loads(record['body'].replace("'", "\""))
        s3_key = body["src_key"]
        schema_missing_retries = 0

        # get schema file
        path = os.path.dirname(s3_key)
        filename = os.path.basename(s3_key).split(".")[0]
        src_path = f"s3://{src_bucket}/{s3_key}"
        schema_file_path = f"{path}/{filename}_schema.json"
        schema = _get_json_file(s3, src_bucket, schema_file_path)

        # if schema doesn't exist, try and throw FileNotFoundError eventually
        while not schema:
            LOGGER.warn(f"Expected schema file, {schema_file_path}, is not found.")
            if schema_missing_retries == MAX_SCHEMA_MISSING_RETRIES:
                raise(FileNotFoundError(schema_file_path))
            
            LOGGER.info(f"Sleep {MAX_SCHEMA_MISSING_RETRIES} seconds and retry..")
            time.sleep(MISSING_SCHEMA_WAIT_TIME)
            schema_missing_retries += 1
            schema = _get_json_file(s3, src_bucket, schema_file_path)

        LOGGER.info(f"Successfully parsed the schema file, {schema_file_path}")
        
        # get the column names by reading the first line of the file
        raw_cols = list(_get_data(src_path, nrows=0).columns)
        # transform raw column names to rs friendly names
        raw_converted = {raw: _get_rs_column_name(raw) for raw in raw_cols}
        converted_cols = list(raw_converted.values())
        
        # check if required fields are in incoming_cols
        missing_fields = _get_missing_required_fields(converted_cols)
        if missing_fields:
            raise Exception(f"One or more equired fields are missing: {str(missing_fields)}")
        
        # make { converted_col: sql data type } 
        updated_schema = {}
        for raw_col in raw_cols:
            converted_col = raw_converted[raw_col]
            if converted_col in COLS_DTYPES.keys():
                updated_schema[converted_col] = COLS_DTYPES[converted_col]
            else:
                for col_set in schema["fields"]:
                    if col_set["name"] == raw_col:
                        updated_schema[converted_col] = _get_rs_data_type(col_set["type"])

            if converted_col not in updated_schema.keys():
                LOGGER.warn(f"Column, {raw_col}, is missing in the schema.")
        
        # get data file in dataframe format
        LOGGER.info(f"Reading {src_path} with a chunk size {CHUNK_SIZE}")
        incoming = _get_data(
            src_path, 
            chunksize=CHUNK_SIZE, 
            columns=converted_cols
        )
        
        """
        --------------------------------------------------------------------------------------------
        SECTION 2: MAP DATA TO REDSHIFT TABLES
        --------------------------------------------------------------------------------------------
        """
        # connect to redshift
        try:
            conn = psycopg2.connect(
                dbname=dbname,
                host=host,
                port="5439",
                user=user_name,
                password=password
            )
            conn.autocommit = 1
        except Exception as e:
            LOGGER.error(
                f"""
                Unable to establish connection to Redshift cluster
                (host: {host}, database: {dbname}, user: {user_name})
                """
            )
            raise e
        
        is_first_batch = True
        table_exist = False
        checked_lookup_vals = set()
        msg_group_id = f"data_transformer_{time.time()}"

        for chunk in incoming:
            # get distinct list of mapping values
            map_values = set(chunk[MAP_FIELD].values)
            table_map_val = {}
            table_df = {}

            # make { rs table: [mapping value] }
            for map_val in map_values:
                rs_table = ""
                try:
                    # get rs table by mapping value from cfg
                    rs_table = cfg.loc[
                        cfg[MAP_FIELD] == map_val,
                        CFG_RS_TABLE
                    ].values[0]
                except IndexError as e:
                    LOGGER.error(
                        f"""
                        Cannot find a RedShift table name for {map_val} in cfg. 
                        Please add the mapping information in cfg and re-run the process.
                        """
                    )
                else:
                    if rs_table in table_map_val.keys():
                        table_map_val[rs_table].append(map_val)
                    else:
                        table_map_val[rs_table] = [map_val]
             
            if len(table_map_val) == 0:
                LOGGER.info("There is no data to insert into RedShift.")
                return {"status_code": 204}
                
            # make { rs table: dataframe(mapping_col=mapping_val) }
            if len(table_map_val) == 1:
                table_df[list(table_map_val.keys())[0]] = chunk
            else:
                for table, map_val in table_map_val.items():
                    # filter data by mapping value
                    table_df[table] = chunk[chunk[MAP_FIELD].isin(map_val)]
            """
            ----------------------------------------------------------------------------------------
            SECTION 3: CREATE STAGING FILES FOR RS_LOADER
            ----------------------------------------------------------------------------------------
            """
            dest_meta = {}
            for table, df in table_df.items():
                # if it is a first chunk of the file
                if is_first_batch:
                    # check if table in redshift by pulling column list
                    rs_cols = _get_rs_table_columns(table, conn)

                    # if table exists
                    if rs_cols:
                        LOGGER.info(f"{table} found in Redshift.")
                        table_exist = True
                        for rs_col in rs_cols.keys():
                            # compare column data type from schema and one from redshift
                            if rs_col in updated_schema.keys():
                                schema_dtype = updated_schema.pop(rs_col)
                                rs_dtype = rs_cols[rs_col]
                                if rs_dtype == "double precision":
                                    rs_dtype = "float"
                                elif rs_dtype == "character varying":
                                    rs_dtype = "varchar(max)"
                                
                                # if the data types don't match, log a warning message
                                if rs_dtype != schema_dtype:
                                    LOGGER.warn(
                                        f"""
                                        !!! DATA TYPE MISMATCH !!!
                                        Column: {rs_col}
                                        Redshift data type: {rs_dtype}
                                        Schema data type: {updated_schema[rs_col]}
                                        Final data type: {rs_dtype}
                                        This may cause an issue when copying the data in Redshift.
                                        """
                                    )
                                    
                if table_exist:
                    # get distinct list of lookup values except the ones that is already checked
                    lookup_vals = set(df[LOOKUP_COL].values)
                    unchecked_lookup_vals = lookup_vals - checked_lookup_vals
                    LOGGER.info(
                        f"""
                        Removing old data whose {LOOKUP_COL} is in:
                            {str(unchecked_lookup_vals)}
                        """
                    )
                    
                    # remove redshift values that match lookup values
                    delete_query = _get_delete_query(table, LOOKUP_COL, unchecked_lookup_vals)
                    with conn.cursor() as cursor:
                        cursor.execute(delete_query)
                    
                    # add checked lookup values to checked_lookup_vals
                    checked_lookup_vals.update(unchecked_lookup_vals)

                # save dataframe into s3
                filename = f'{table}_{time.time()}'
                s3_key = _save_staging_file_in_s3(s3, staging_bucket, filename, df)

                # make { table: { staging s3 key, columns } }
                if table not in dest_meta.keys():
                    dest_meta[table] = {"s3_key": s3_key, "columns": str(converted_cols)}
            
            # send message to rs_loader SQS
            for dest, meta in dest_meta.items():
                sqs.send_message(
                    QueueUrl=target_sqs_url,
                    MessageBody=json.dumps({
                        "table": dest,
                        "columns": meta["columns"],
                        "s3_key": meta["s3_key"],
                        "missing_columns": str(updated_schema),
                        "delimiter": DELIMITER,
                        "is_first_batch": is_first_batch,
                        "table_exist": table_exist
                    }),
                    MessageGroupId=msg_group_id
                )
                LOGGER.info(f"Sent {meta['s3_key']} information to rs_loader process")
            is_first_batch = False
            updated_schema = {}
        conn.close()


def _get_rs_data_type(schema_dtype):
    """
    Returns: SQL data type; either varchar(max) or float -> str
    
    This function translates data type from schema file to SQL data type.
    
    Parameter schema_dtype: data type from schema file
    Precondition: schema_dtype is str
    """
    schema_dtype = schema_dtype.lower()
    if schema_dtype == "numeric":
        return "float"
    return "varchar(max)"


def _get_json_file(s3_resource, bucket, key):
    """
    Returns: JSON file content -> JSON object or empty dict
    
    This function reads JSON S3 object
    
    Parameter s3_resource: S3 object
    Precondition: s3_resource is boto3.resource('s3')

    Parameter bucket: S3 bucket that contains json file
    Precondition: bucket is str

    Parameter key: S3 key of the json file
    Precondition: key is str
    """
    try:
        obj = s3_resource.Object(bucket, key)
        data = obj.get()["Body"].read()
        return json.loads(data)
    except Exception:
        return {}
    

def _get_rs_table_columns(table, conn):
    """
    Returns: list of redshift table column names and data types -> list
    
    This function queries column schema of the given table
    
    Parameter table: Redshif table
    Precondition: table is str

    Parameter conn: Redshift connection
    Precondition: conn is psycopg2.connection object
    """
    rs_cols = []
    # get columns from redshift table
    get_columns_query = _get_select_query(
        ["column_name", "data_type"], 
        "information_schema.columns", 
        [f"table_name = '{table}'"]
    )
    
    with conn.cursor() as cursor:
        cursor.execute(get_columns_query)
        rs_cols = {result[0]: result[1] for result in cursor.fetchall()}
    
    return rs_cols


def _save_staging_file_in_s3(s3_resource, bucket, filename, df):
    """
    Returns: S3 key of the staging file -> str
    
    This function creates a staging file in a given bucket
    
    Parameter s3_resource: S3 object
    Precondition: s3_resource is boto3.resource('s3')

    Parameter bucket: S3 bucket that contains staging file
    Precondition: bucket is str

    Parameter filename: Name of the staging file
    Precondition: filename is str

    Parameter df: Dataframe that contains data to store in staging file
    Precondition: df is pandas.DataFrame
    """
    gz_buffer = BytesIO()
    with gzip.GzipFile(mode='w', fileobj=gz_buffer) as gz_file:
        df.to_csv(TextIOWrapper(gz_file, 'utf8'), index=False, sep=DELIMITER)
    s3_key = f'{filename}.gz'
    LOGGER.info(f"Writing {s3_key} in {bucket}...")
    s3_resource.Object(bucket, s3_key).put(Body=gz_buffer.getvalue())
    LOGGER.info(f"Completed writing {s3_key}")
    return s3_key

    
def _get_data(file, chunksize=0, nrows=None, columns=None):
    """
    Returns: data in file -> pandas.DataFrame
    
    This function reads file based on the file type and delimiter.
    
    Parameter file: a file path
    Precondition: file is str
                  file type is csv, txt, json, or xml
    """
    ext = os.path.splitext(file)[1].lower()
    args = {}
    if chunksize:
        args["chunksize"] = chunksize
    if nrows is not None:
        args["nrows"] = nrows
    if columns:
        args["names"] = columns
        args["skiprows"] = 1
        args["header"] = None
        
    if ext in [".csv", ".txt"]:
        if ext == ".txt":
            args["delimiter"] = DELIMITER
        return pd.read_csv(file, **args)
    elif ext == ".json":
        return pd.read_json(file, **args)
    elif ext == ".xml":
        return pd.read_xml(file, **args)
    else:
        raise Exception("Unknown file type: {}".format(ext))


def _get_missing_required_fields(incoming_cols):
    """
    Returns: required fields exist, column name -> bool, str or None
    
    This function checks if the required columns are in incoming_cols. If any column is not in 
    incoming_cols, return False and the column name.
    
    Parameter incoming_cols: column headers of incoming data
    Precondition: incoming_cols is [str]
    """
    missing_fields = []
    for col in REQUIRED_COLS:
        if col.lower() not in incoming_cols:
            missing_fields.append(col)
    
    return missing_fields

    
def _get_rs_column_name(name):
    """
    Returns: a column name that follows RedShift column naming convention -> str
    
    This function replaces invaild column name value for Redshift and adds '_' in front of the 
    column name if the first character is not Redshift compatible. It also checks the Redshift 
    column name length constraint.
    
    Parameter name: incoming column name
    Precondition: name is str
    """
    allowed_first_char = ["@", "_", "#"]
    replace_vals = {
        ".": "_", 
        " ": "_", 
        "/": "_", 
        "-": "_", 
        ":": "_"
    }

    for key, val in replace_vals.items():
        name = name.replace(key, val)
    
    first_char = name[0]
    if not (first_char.isalpha() or first_char in allowed_first_char):
        LOGGER.info(f"Transforming column {name} to _{name}")
        name = f"_{name}"

    if len(name) > 115:
        LOGGER.warn(f"Column {name} is too long. The name may be truncated in Redshift.")
    return name.lower()


def _get_select_query(columns, table, conditions):
    """
    Returns: a SQL SELECT query -> str
    
    Parameter columns: RedShift columns to look up
    Precondition: columns is [str]
    
    Parameter table: RedShift table name
    Precondition: table is str
    
    Parameter conditions: SQL conditions to filter the search values
    Precondition: conditions is [str]
                  str is in valid SQL condition format
    """
    return f"""
    SELECT {",".join(columns)}
    FROM {table.lower()}
    WHERE {" AND ".join(conditions)}
    """


def _get_delete_query(table, column_name, column_vals):
    """
    Returns: a SQL SELECT query -> str
    
    Parameter table: RedShift table name
    Precondition: table is str
    
    Parameter column_name: RedShift column name
    Precondition: column_name is str
    
    Parameter column_vals: column values to delete
    Precondition: column_vals is [str]
    """
    return f"""
    DELETE FROM {table}
    WHERE {column_name} IN ('{"','".join(column_vals)}')
    """