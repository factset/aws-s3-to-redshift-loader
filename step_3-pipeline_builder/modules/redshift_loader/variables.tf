variable "name_prefix" {
  description = "Prefix for named resources"
  type        = string
  default     = ""
}

# ------------------------------------------------------------------------------
# Data Bucket
# ------------------------------------------------------------------------------
variable "staging_bucket" {
  description = "Bucket in which the data is stored."
  type        = string
}

# ------------------------------------------------------------------------------
# VPC
# ------------------------------------------------------------------------------
variable "subnets" {
  description = "list of subnets"
  type        = list(string)
}

# ------------------------------------------------------------------------------
# Redshift
# ------------------------------------------------------------------------------
variable "rs_database_name" {
  description = "Database name to load the data"
  type        = string
}

variable "rs_master_username" {
  description = "Redshift username"
  type        = string
  sensitive   = true
}

variable "rs_master_pass" {
  description = "Redshift password"
  type        = string
  sensitive   = true
}

variable "rs_schema" {
  description = "Redshift schema name"
  type        = string
}

variable "rs_execution_role_arn" {
  description = "IAM role ARN that can access Redshift from lambda"
  type        = string
}

variable "rs_cluster_dns_name" {
  description = "DNS name of Redshift cluster"
  type        = string
}

variable "security_group_ids" {
  description = "Redshift security group ids"
  type        = list(string)
}

# ------------------------------------------------------------------------------
# Lambda
# ------------------------------------------------------------------------------
variable "lambda_layer_arn" {
  description = "ARN of the Lambda dependency layer"
  type        = string
}

variable "rs_loader_sqs_arn" {
  description = "ARN of the SQS that will be a trigger for the Lambda"
  type        = string
}

# ------------------------------------------------------------------------------
# SNS
# ------------------------------------------------------------------------------
variable "error_alert_sns_topic_arn" {
  description = "SNS topic ARN for alerting an error in lambdas"
  type        = string
}