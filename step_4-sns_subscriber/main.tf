terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      version = "~> 4.0"
      source  = "hashicorp/aws"
    }
  }
}

# Used for the bucket in which data from data source will be copied into and to create
# the subscription connecting the data source SNS topic to the local "s3-copy-queue" SQS
# queue.
provider "aws" {
  region  = var.data_source_aws_region
  profile = var.aws_profile

  assume_role {
    role_arn = var.iam_role_arn
  }

  default_tags {
    tags = {
      Project = "Data Source S3 To Redshift Loader"
    }
  }
}

resource "aws_sns_topic_subscription" "data_copier_sqs_target" {
  topic_arn = var.data_source_sns_arn
  protocol  = "sqs"
  endpoint  = var.data_copier_sqs_arn

  raw_message_delivery = true
}