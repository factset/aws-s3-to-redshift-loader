variable "iam_role_name" {
  description = "Name of the IAM role"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for named resources"
  type        = string
  default     = ""
}

variable "data_destination_aws_region" {
  description = "AWS region in which data destination's bucket is in"
  type        = string
}

variable "aws_profile" {
  description = "AWS credential profile"
  type        = string
  default     = ""
}