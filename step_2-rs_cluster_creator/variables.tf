variable "name_prefix" {
  description = "Prefix for named resources"
  type        = string
  default     = ""
}

variable "iam_role_arn" {
  description = "ARN of IAM role"
  type        = string
}

# ------------------------------------------------------------------------------
# VPC
# ------------------------------------------------------------------------------
variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnets" {
  description = "List of subnets"
  type        = list(string)
}

# ------------------------------------------------------------------------------
# Redshift
# ------------------------------------------------------------------------------
variable "rs_cluster_name" {
  description = "Name of the Redshift cluster"
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

variable "rs_node_type" {
  description = "Redshift node type"
  type        = string
}

variable "rs_cluster_type" {
  description = "Redshift cluster type. Either single-node or multi-node"
  type        = string
}

variable "rs_subnet_group_name" {
  description = "Redshift subnet group name"
  type        = string
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