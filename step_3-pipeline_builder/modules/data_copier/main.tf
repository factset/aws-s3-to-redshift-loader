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
resource "aws_s3_bucket" "data_bucket" {
  bucket = "${var.name_prefix}${var.data_bucket_name}"

  tags = {
    Name = "${var.name_prefix}${var.data_bucket_name}"
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

resource "aws_sqs_queue" "data_copier_sqs" {
  name                        = "${var.name_prefix}data_copier-queue.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  message_retention_seconds   = 60
  policy                      = data.aws_iam_policy_document.sqs_policy_doc.json

  tags = {
    Name = "${var.name_prefix}data_copier-queue.fifo"
  }
}

resource "aws_sqs_queue" "data_transformer_sqs" {
  name                        = "${var.name_prefix}data_transformer-queue.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  visibility_timeout_seconds  = 900
  message_retention_seconds   = 60
  policy                      = data.aws_iam_policy_document.sqs_policy_doc.json

  tags = {
    Name = "${var.name_prefix}data_transformer-queue.fifo"
  }
}

# ------------------------------------------------------------------------------
# SNS
# ------------------------------------------------------------------------------
resource "aws_sns_topic" "error_alert_sns_topic" {
  name = "data_delivery_pipeline_lambda_error_alert"
}

resource "aws_sns_topic_subscription" "error_alert_target" {
  topic_arn = aws_sns_topic.error_alert_sns_topic.arn
  protocol  = "email"
  endpoint  = var.email_alert_recipient
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
    command = <<-EOT
    python -m pip install --platform=manylinux2014_x86_64 --only-binary=:all: -r ${path.module}/lambda_src/requirements_frozen.txt -t ${path.module}/build/lambda
    cp ${path.module}/lambda_src/main.py ${path.module}/build/lambda
    EOT
    interpreter = [ "PowerShell", "-c" ]
  }
}

# Package lambda
data "archive_file" "lambda_package" {
  type        = "zip"
  source_dir  = "${path.module}/build/lambda"
  output_path = "${path.module}/build/lambda.zip"
  depends_on  = [null_resource.pip_install]
}

# Create Lambda
resource "aws_lambda_function" "data_copier" {
  function_name    = "${var.name_prefix}data-copier"
  filename         = data.archive_file.lambda_package.output_path
  source_code_hash = data.archive_file.lambda_package.output_base64sha256
  role             = var.iam_role_arn
  handler          = "main.lambda_handler"
  runtime          = "python3.9"
  timeout          = 30
  memory_size      = 2500

  environment {
    variables = {
      data_destination_region   = data.aws_region.current.name
      data_source_region        = var.data_source_aws_region
      src_bucket                = var.data_source_access_point_alias
      dst_bucket                = aws_s3_bucket.data_bucket.id
      data_transformer_sqs_url  = aws_sqs_queue.data_transformer_sqs.url
    }
  }

  depends_on = [data.archive_file.lambda_package]
}

# Trigger lambda event source
resource "aws_lambda_event_source_mapping" "trigger_data_copier_lambda" {
  event_source_arn = aws_sqs_queue.data_copier_sqs.arn
  function_name    = aws_lambda_function.data_copier.arn

  enabled    = true
  batch_size = 1

  depends_on = [aws_lambda_function.data_copier]
}

# ------------------------------------------------------------------------------
# CloudWatch Alarm
# ------------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "data_copier_error_alarm" {
  alarm_name          = "data_copier_error_alarm"
  alarm_description   = "Data copier error alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 1
  period              = 60
  unit                = "Count"

  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  statistic           = "Maximum"

  dimensions = {
      FunctionName = aws_lambda_function.data_copier.function_name
  }

  alarm_actions = ["${aws_sns_topic.error_alert_sns_topic.arn}"]
}