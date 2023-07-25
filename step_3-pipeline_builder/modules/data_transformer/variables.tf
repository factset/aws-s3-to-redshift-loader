variable "name_prefix" {
  description = "Prefix for named resources"
  type        = string
  default     = ""
}

# ------------------------------------------------------------------------------
# Data Bucket
# ------------------------------------------------------------------------------
variable "data_src_bucket_id" {
  description = "Bucket in which the data is stored."
  type        = string
}

variable "staging_bucket_name" {
  description = "Bucket in which the data will be stored temporarily for processing."
  type        = string
}

# ------------------------------------------------------------------------------
# SQS
# ------------------------------------------------------------------------------
variable "data_transformer_sqs_arn" {
  description = "SQS ARN that data_transformer lambda will subscribe to"
  type        = string
}

# ------------------------------------------------------------------------------
# SNS
# ------------------------------------------------------------------------------
variable "error_alert_sns_topic_arn" {
  description = "SNS topic ARN for alerting an error in lambdas"
  type = string
}

variable "subnets" {
  description = "list of subnets"
  type        = list(string)
}

variable "rs_execution_role_arn" {
  description = "IAM role ARN that can access Redshift from lambda"
  type        = string
}

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

variable "rs_cluster_dns_name" {
  description = "DNS name of the Redshift cluster"
  type        = string
  sensitive   = true
}

variable "security_group_ids" {
  description = "Redshift security group ids"
  type        = list(string)
}