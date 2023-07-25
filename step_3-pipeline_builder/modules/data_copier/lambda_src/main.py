import boto3
import logging
import time
import os

from smart_open import open

logger = logging.getLogger()
logger.setLevel(logging.INFO)

TARGET_DIRS = ["direct"]

def lambda_handler(event, context):
    logger.info("Starting a copy process...")

    # copy from s3 using the access point
    src_bucket = os.getenv("src_bucket")
    dst_bucket = os.getenv("dst_bucket")
    data_source_region = os.getenv("data_source_region")
    data_destination_region = os.getenv("data_destination_region")
    target_sqs_url = os.getenv("data_transformer_sqs_url")

    extra_args = {
        "RequestPayer": "requester"
    }

    s3 = boto3.resource("s3")
    sqs = boto3.client("sqs")

    for record in event["Records"]:
        s3_key = record["body"]
        path_elements = s3_key.split("/")
        if path_elements[0].lower() not in TARGET_DIRS:
            logger.info(f"Skipping an irrelevant file: {s3_key}")
            continue

        copy_source = {
            "Bucket": src_bucket,
            "Key": s3_key
        }
        dst_s3_key = s3_key.lower()
        logger.info(f"Copying {s3_key} as {dst_s3_key}...")
        if data_destination_region == data_source_region:
            s3.meta.client.copy(CopySource=copy_source, Bucket=dst_bucket, Key=dst_s3_key, ExtraArgs=extra_args)
            logger.info(f"Copied {dst_s3_key} successfully.")
        else:
            stream_url = f"s3://{src_bucket}/{s3_key}"
            params = {"client_kwargs": {"S3.Client.get_object": extra_args}, "client": s3.meta.client}
            
            with open(stream_url, "rb", buffering=0, transport_params=params) as f:
                s3.meta.client.put_object(Bucket=dst_bucket, Key=dst_s3_key, Body=f.read())
                logger.info(f"Copied {dst_s3_key} successfully.")

        if "schema" not in dst_s3_key:
            sqs.send_message(
                QueueUrl=target_sqs_url,
                MessageBody=str({
                    "src_key": dst_s3_key
                }),
                MessageGroupId=f"data_copier_{time.time()}"
            )
            logger.info("Successfully sent a message to the data_transformer process.")
