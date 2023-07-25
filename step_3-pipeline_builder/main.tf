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

module "data_copier" {
  source = "./modules/data_copier"

  iam_role_arn        = var.iam_role_arn

  data_source_aws_region          = var.data_source_aws_region
  data_source_access_point_alias  = var.data_source_access_point_alias
  data_bucket_name                = var.data_bucket_name
  email_alert_recipient           = var.email_alert_recipient

  name_prefix = var.name_prefix
}

module "data_transformer" {
  source = "./modules/data_transformer"

  staging_bucket_name = var.staging_bucket_name
  subnets             = var.subnets
  security_group_ids  = var.security_group_ids

  data_transformer_sqs_arn  = module.data_copier.data_transformer_sqs_arn
  data_src_bucket_id        = module.data_copier.data_dest_bucket_id
  error_alert_sns_topic_arn = module.data_copier.error_alert_sns_topic_arn

  rs_database_name      = var.rs_database_name
  rs_master_pass        = var.rs_master_pass
  rs_master_username    = var.rs_master_username
  rs_cluster_dns_name   = var.rs_cluster_dns_name
  rs_execution_role_arn = var.rs_execution_role_arn != "" ? var.rs_execution_role_arn : var.iam_role_arn

  name_prefix = var.name_prefix

  depends_on = [
    module.data_copier
  ]
}

module "redshift_loader" {
  source = "./modules/redshift_loader"

  subnets             = var.subnets

  lambda_layer_arn          = module.data_transformer.lambda_layer_arn
  rs_loader_sqs_arn         = module.data_transformer.rs_loader_sqs_arn
  staging_bucket            = module.data_transformer.staging_bucket
  error_alert_sns_topic_arn = module.data_copier.error_alert_sns_topic_arn

  rs_database_name    = var.rs_database_name
  rs_master_pass      = var.rs_master_pass
  rs_master_username  = var.rs_master_username
  rs_schema           = var.rs_schema
  rs_cluster_dns_name       = var.rs_cluster_dns_name
  security_group_ids        = var.security_group_ids
  rs_execution_role_arn     = var.rs_execution_role_arn != "" ? var.rs_execution_role_arn : var.iam_role_arn

  name_prefix = var.name_prefix

  depends_on = [
    module.data_transformer
  ]
}
