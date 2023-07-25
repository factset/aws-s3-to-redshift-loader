variable "data_source_sns_arn" {
  description = "(Required) Data Source's SNS ARN to be subscribed by SQS for file notifications"
  type        = string
}

variable "data_copier_sqs_arn" {
  description = "(Required) ARN of SQS that will trigger data_copier"
  type        = string
}

variable "iam_role_arn" {
  description = "ARN of IAM role"
  type        = string
}

variable "data_source_aws_region" {
  description = "(Required) AWS region in which data source's bucket is in"
  type        = string
}

variable "aws_profile" {
  description = "AWS credential profile"
  type        = string
  default     = ""
}