import os
import json

import boto3
import psycopg2
import logging

LOGGER = logging.getLogger()
LOGGER.setLevel(logging.INFO)

HOST = "host"
SCHEMA_NAME = "schema"
IAM_ROLE = "iam_role"
DATA_REGION = "data_region"
DB_NAME = "database_name"
USR_NAME = "user_name"
PASSWORD = "password"
SRC_BUCKET = "src_bucket"
SAMPLE_SIZE = 100

def lambda_handler(event, context):
    LOGGER.info(f"Starting rs_loader process...")
    """
    ------------------------------------------------------------------------------------------------
    SECTION 1: GET VARIABLES
    ------------------------------------------------------------------------------------------------
    """
    schema_name = os.getenv(SCHEMA_NAME)
    host = os.getenv(HOST)
    dbname = os.getenv(DB_NAME)
    user_name = os.getenv(USR_NAME)
    password = os.getenv(PASSWORD)
    iam_role = os.getenv(IAM_ROLE)
    data_region = os.getenv(DATA_REGION)
    src_bucket = os.getenv(SRC_BUCKET)
    
    # connect to redshift
    try:
        conn = psycopg2.connect(
            dbname=dbname,
            host=host,
            port="5439",
            user=user_name,
            password=password
        )
        conn.autocommit = True
    except Exception as e:
        LOGGER.error(
            f"""
            Unable to establish connection to Redshift cluster
            (host: {host}, database: {dbname}, user: {user_name})
            """
        )
        raise e
    
    for record in event["Records"]:
        body = json.loads(record["body"])
        table = body["table"]
        columns = json.loads(body["columns"].replace("'", '"'))
        s3_key = body["s3_key"]
        delimiter = body["delimiter"]
        is_first_batch = body["is_first_batch"]

        s3_path = f"s3://{src_bucket}/{s3_key}"
        
        """
        ------------------------------------------------------------------------------------------------
        SECTION 2: PREPARE REDSHIFT TABLE
        ------------------------------------------------------------------------------------------------
        """
        # if it is a first batch of a data file
        if is_first_batch:
            missing_columns = json.loads(body["missing_columns"].replace("'", '"'))

            # if table doesn't exist create table
            if not body["table_exist"]:
                cols = [f"{col} {dtype}" for col, dtype in missing_columns.items()]
                LOGGER.info(f"Creating a table, {table}, in Redshift...")
                response = _create_table(conn, table, cols)
                if response == 201:
                    missing_columns = {}
            
            # if there are missing columns, create columns to a redshift table
            while missing_columns:
                col, dtype = missing_columns.popitem()
                response = _add_column(conn, table, col, dtype)
        
        """
        ------------------------------------------------------------------------------------------------
        SECTION 3: COPY DATA
        ------------------------------------------------------------------------------------------------
        """
        _copy_data(conn, s3_path, table, columns, delimiter, schema_name, iam_role, data_region)
        _delete_s3_obj(src_bucket, s3_key)

    
def _copy_data(conn, s3_path, table, columns, delimiter, schema_name, iam_role, data_region):
    """
    This function copies a file from S3 to a redshift table
    
    Parameter conn: Redshift connection
    Precondition: conn is psycopg2.connection object

    Parameter s3_path: S3 path of the json file
    Precondition: key is str
                  format is "s3://{bucket name}/{s3 key}"

    Parameter table: Redshif table
    Precondition: table is str

    Parameter columns: Redshift column names
    Precondition: columns is [str]

    Parameter delimiter: Delimiter of the file
    Precondition: delimiter is str

    Parameter schema_name: Redshift schema name
    Precondition: schema_name is str

    Parameter iam_role: IAM role that has access to redshift
    Precondition: iam_role is str
                  iam_role name should already exist in AWS

    Parameter data_region: AWS region that has s3_path exists
    Precondition: data_region is str
    """
    LOGGER.info(f"Copying from {s3_path} to {table}...")
    
    copy_query = f"""
    COPY {schema_name}.{table} ({",".join(columns)}) FROM '{s3_path}'
    IAM_ROLE '{iam_role}'
    IGNOREHEADER AS 1
    FORMAT AS DELIMITER AS '{delimiter}' 
    TRUNCATECOLUMNS
    REGION AS '{data_region}'
    gzip;
    """
    
    with conn.cursor() as cursor:
        cursor.execute(copy_query)
    
    
def _add_column(conn, table, column, column_dtype, default="NULL"):
    """
    This function adds a column to a Redshift table
    
    Parameter conn: Redshift connection
    Precondition: conn is psycopg2.connection object

    Parameter table: Redshif table
    Precondition: table is str

    Parameter column: new column name
    Precondition: column is str

    Parameter column_dtype: column's data type
    Precondition: column_dtype is str

    Parameter default: column default value
    Precondition: default is str
    """
    LOGGER.info(f"Adding column {column} as {column_dtype} to {table}...")
    
    alter_query = f"""
    ALTER TABLE {table}
    ADD COLUMN {column} {column_dtype}
    DEFAULT {default};
    """
    
    try:
        with conn.cursor() as cursor:
            cursor.execute(alter_query)
    except psycopg2.errors.DuplicateColumn:
        LOGGER.warn(f"Column {column} already exists.")

    
def _create_table(conn, table, column_schema):
    """
    Returns: Process status code -> int

    This function creates a redshift table
    
    Parameter conn: Redshift connection
    Precondition: conn is psycopg2.connection object

    Parameter table: Redshif table
    Precondition: table is str

    Parameter column_schema: Redshift column schema
    Precondition: column_schema is [str]
                  str is in "{column name} {column data type}" format
    """
    create_table_query = f"""
    CREATE TABLE {table} (
    {",".join(column_schema)}
    );
    """
    
    try:
        with conn.cursor() as cursor:
            cursor.execute(create_table_query)
        return 201
    except psycopg2.errors.DuplicateTable:
        LOGGER.warn(f"Table {table} already exists.")
        return 403


def _delete_s3_obj(bucket, key):
    """
    This function deletes an S3 object

    Parameter bucket: S3 bucket that has a given key
    Precondition: bucket is str
                  bucket should already exist in AWS

    Parameter key: S3 object key
    Precondition: key is str
                  key should already exist in AWS
    """
    LOGGER.info(f"Deleting {key} from {bucket}...")
    s3_resource = boto3.resource('s3')
    s3_resource.Object(bucket, key).delete()