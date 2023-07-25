variable "name_prefix" {
  description = "Prefix for named resources"
  type        = string
  default     = ""
}

variable "iam_role_arn" {
  description = "(Required) ARN of the AWS Data Delivery Role"
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

variable "data_bucket_name" {
  description = "(Required) Destination bucket in which the data will be copied to"
  type        = string
}

variable "email_alert_recipient" {
  description = "Email address that will recieve an error alert" 
  type        = string 
}