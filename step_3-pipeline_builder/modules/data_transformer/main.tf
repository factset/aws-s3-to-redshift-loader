terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      version = "~> 4.0"
      source  = "hashicorp/aws"
    }
  }
}

data "aws_region" "current" {}

# ------------------------------------------------------------------------------
# S3 Data Bucket
# ------------------------------------------------------------------------------
resource "aws_s3_bucket" "staging_bucket" {
  bucket = "${var.name_prefix}${var.staging_bucket_name}"

  tags = {
    Name = var.staging_bucket_name
  }
}

# ------------------------------------------------------------------------------
# SQS
# ------------------------------------------------------------------------------
data "aws_iam_policy_document" "sqs_policy_doc" {
  statement {
    sid = "SQSAllowReceive"
    actions = [ "SQS:*" ]
    resources = [ "*" ]
    principals {
      type = "AWS"
      identifiers = [ "*" ]
    }
    effect = "Allow"
  }
}

resource "aws_sqs_queue" "rs_loader_sqs" {
  name                        = "${var.name_prefix}rs-loader-queue.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  visibility_timeout_seconds  = 900
  message_retention_seconds   = 60
  policy = data.aws_iam_policy_document.sqs_policy_doc.json

  tags = {
    Name = "${var.name_prefix}rs-loader-queue.fifo"
  }
}

# ------------------------------------------------------------------------------
# Lambda
# ------------------------------------------------------------------------------
# Install Dependencies
resource "null_resource" "pip_install" {
  triggers = {
    build_number = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "python -m pip install --platform=manylinux2014_x86_64 --only-binary=:all: -r ${path.module}/lambda_src/requirements_frozen.txt -t ${path.module}/build/layer/python"
  }
}

# Create zip file of layer
data "archive_file" "layer" {
  type        = "zip"
  source_dir  = "${path.module}/build/layer"
  output_path = "${path.module}/build/layer.zip"
  excludes    = ["python/botocore"]
  depends_on  = [null_resource.pip_install]
}

# Bucket to hold Lambda layer package
resource "aws_s3_bucket" "data_transformer_lambda_package" {
  bucket_prefix = "${var.name_prefix}data-transformer-lambda-pkg-"
}

# Place lambda layer in S3
resource "aws_s3_object" "layer" {
  bucket = aws_s3_bucket.data_transformer_lambda_package.id
  key    = "layer.zip"
  source = data.archive_file.layer.output_path
  etag   = data.archive_file.layer.output_md5
}

# Create layer in AWS
resource "aws_lambda_layer_version" "layer" {
  layer_name = "lambda-redshift-layer"
  s3_bucket  = aws_s3_bucket.data_transformer_lambda_package.id
  s3_key     = aws_s3_object.layer.key
  #filename            = data.archive_file.layer.output_path
  source_code_hash    = data.archive_file.layer.output_base64sha256
  compatible_runtimes = ["python3.9"]
  depends_on          = [data.archive_file.layer]
}

# Package lambda
data "archive_file" "lambda_package" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_src"
  output_path = "${path.module}/build/lambda.zip"
}

resource "aws_lambda_function" "data_transformer" {
  function_name = "${var.name_prefix}data-transformer"

  role    = var.rs_execution_role_arn
  handler = "main.lambda_handler"
  runtime = "python3.9"

  filename         = data.archive_file.lambda_package.output_path
  source_code_hash = data.archive_file.lambda_package.output_base64sha256

  timeout = 900
  memory_size = 2500
  layers = [aws_lambda_layer_version.layer.arn]

  vpc_config {
    subnet_ids         = var.subnets
    security_group_ids = var.security_group_ids
  }

  environment {
    variables = {
      database_name = var.rs_database_name
      user_name     = var.rs_master_username
      password      = var.rs_master_pass
      host          = var.rs_cluster_dns_name
      rs_loader_sqs_url = aws_sqs_queue.rs_loader_sqs.url
      staging_bucket    = aws_s3_bucket.staging_bucket.id
      src_bucket        = var.data_src_bucket_id
    }
  }

  depends_on = [data.archive_file.lambda_package]
}

# Lambda trigger
resource "aws_lambda_event_source_mapping" "trigger_data_transformer" {
  event_source_arn = var.data_transformer_sqs_arn
  function_name    = aws_lambda_function.data_transformer.arn

  enabled    = true
  batch_size = 1

  depends_on = [aws_lambda_function.data_transformer]
}

# ------------------------------------------------------------------------------
# CloudWatch Alarm
# ------------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "data_transformer_error_alarm" {
  alarm_name          = "data_transformer_error_alarm"
  alarm_description   = "Data transformer error alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 1
  period              = 60
  unit                = "Count"

  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  statistic           = "Maximum"

  dimensions = {
      FunctionName = aws_lambda_function.data_transformer.function_name
  }

  alarm_actions = [
    "${var.error_alert_sns_topic_arn}"
  ]
}