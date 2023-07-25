variable "name_prefix" {
  description = "Prefix for named resources"
  type        = string
  default     = ""
}

variable "aws_profile" {
  description = "AWS credential profile"
  type        = string
  default     = ""
}

variable "iam_role_arn" {
  description = "(Required) ARN of the AWS Data Delivery Role"
  type        = string
}

variable "rs_execution_role_arn" {
  description   = "ARN of the RedShift execution role"
  type          = string
  default       = ""
}

variable "rs_cluster_dns_name" {
  description = "(Required) DNS name of the Redshift cluster"
  type        = string
}

variable "data_source_access_point_alias" {
  description = "(Required) Data Source's S3 Access Point ARN"
  type        = string
}

variable "data_source_aws_region" {
  description = "(Required) AWS region in which data source's bucket is in"
  type        = string
}

variable "data_destination_aws_region" {
  description = "(Required) AWS region in which data destination's bucket is in"
  type        = string
}

variable "data_bucket_name" {
  description = "(Required) Destination bucket in which the data will be copied to"
  type        = string
}

variable "email_alert_recipient" {
  description = "Email address that will recieve an error alert" 
  type        = string 
}

variable "subnets" {
  description = "list of subnets"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Redshift security group ids"
  type        = list(string)
}

variable "staging_bucket_name" {
  description = "Bucket in which the data will be stored temporarily for processing."
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

variable "rs_schema" {
  description = "Redshift schema name"
  type        = string
  default     = "public"
}