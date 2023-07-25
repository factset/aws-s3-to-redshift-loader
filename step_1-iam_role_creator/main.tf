terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      version = "~> 4.0"
      source  = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region  = var.data_destination_aws_region
  profile = var.aws_profile
  default_tags {
    tags = {
      Project = "Data Source S3 To Redshift Loader"
    }
  }
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "assume_role_policy_doc" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = ["lambda.amazonaws.com", "sqs.amazonaws.com", "redshift.amazonaws.com"]
    }

    principals {
      type = "AWS"
      identifiers = [data.aws_caller_identity.current.arn]
    }
  }
}

resource "aws_iam_role" "aws_data_delivery_role" {
  name = "${var.name_prefix}${var.iam_role_name}"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_doc.json
}

data "aws_iam_policy_document" "role_policy_doc" {
  statement {
    sid = "KMSDecrypt"
    actions = [ "kms:Decrypt" ]
    resources = ["*"]
    effect = "Allow"
  }
  statement {
    sid = "SNSSubscription"
    actions = [
      "sns:Subscribe",
      "sns:Unsubscribe",
      "sns:ListTopics",
      "sns:ListSubscriptions",
      "sns:GetSubscriptionAttributes"
    ]
    resources = [ "*" ]
    effect = "Allow"
  }
  statement {
    sid = "S3ObjectAccess"
    actions = [ 
      "s3:GetObject*",
      "s3:PutObject*",
      "s3:DeleteObject"
    ]
    resources = [ "*" ]
    effect = "Allow"
  }
  statement {
    sid = "S3List"
    actions = [ 
      "s3:ListBucket*"
    ]
    resources = [ "*" ]
    effect = "Allow"
  }
  statement {
    sid = "BasicSQSPolicy"
    actions = [ 
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:SendMessage"
    ]
    resources = [ "*" ]
    effect = "Allow"
  }
  statement {
    sid = "BasicLambdaExecution"
    actions = [ 
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [ "*" ]
    effect = "Allow"
  }
  statement {
    sid = "EC2Interfaces"
    actions = [ 
      "ec2:DescribeNetworkInterfaces",
      "ec2:CreateNetworkInterface",
      "ec2:DeleteNetworkInterface",
      "ec2:AssignPrivateIpAddresses",
      "ec2:UnassignPrivateIpAddresses",
      "ec2:DescribeInstances",
      "ec2:AttachNetworkInterface"
    ]
    resources = [ "*" ]
    effect = "Allow"
  }
}

resource "aws_iam_role_policy" "aws_data_delivery_role_policy" {
  name = "${var.name_prefix}${var.iam_role_name}-policy"
  role = aws_iam_role.aws_data_delivery_role.id
  policy = data.aws_iam_policy_document.role_policy_doc.json
}
