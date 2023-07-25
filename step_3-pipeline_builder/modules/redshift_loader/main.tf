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
# Lambda
# ------------------------------------------------------------------------------
# Package lambda
data "archive_file" "lambda_package" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_src"
  output_path = "${path.module}/build/lambda.zip"
}

# Lambda
resource "aws_lambda_function" "rs_loader" {
  function_name = "${var.name_prefix}redshift-loader"

  role    = var.rs_execution_role_arn
  handler = "main.lambda_handler"
  runtime = "python3.9"

  filename         = data.archive_file.lambda_package.output_path
  source_code_hash = data.archive_file.lambda_package.output_base64sha256

  timeout = 900
  memory_size = 2500
  layers  = [var.lambda_layer_arn]

  vpc_config {
    subnet_ids         = var.subnets
    security_group_ids = var.security_group_ids
  }

  environment {
    variables = {
      src_bucket  = var.staging_bucket
      data_region = data.aws_region.current.name
      database_name = var.rs_database_name
      user_name     = var.rs_master_username
      password      = var.rs_master_pass
      schema        = var.rs_schema
      iam_role = var.rs_execution_role_arn
      host     = var.rs_cluster_dns_name
    }
  }

  depends_on = [data.archive_file.lambda_package]
}

# Lambda trigger
resource "aws_lambda_event_source_mapping" "trigger_rs_loader" {
  event_source_arn = var.rs_loader_sqs_arn
  function_name    = aws_lambda_function.rs_loader.arn

  enabled    = true
  batch_size = 1

  depends_on = [aws_lambda_function.rs_loader]
}

# ------------------------------------------------------------------------------
# CloudWatch Alarm
# ------------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "rs_loader_error_alarm" {
  alarm_name          = "rs_loader_error_alarm"
  alarm_description   = "Redshift loader error alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 1
  period              = 60
  unit                = "Count"

  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  statistic           = "Maximum"

  dimensions = {
      FunctionName = aws_lambda_function.rs_loader.function_name
  }

  alarm_actions = ["${var.error_alert_sns_topic_arn}"]
}