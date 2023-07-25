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

data "aws_vpc" "selected" {
  id = var.vpc_id
}

resource "aws_redshift_subnet_group" "rs_subnet_group" {
  name       = "${var.name_prefix}${var.rs_subnet_group_name}"
  subnet_ids = var.subnets

  tags = {
    Name = "${var.name_prefix}${var.rs_subnet_group_name}"
  }
}

resource "aws_default_security_group" "rs_security_group" {
  vpc_id = data.aws_vpc.selected.id

  ingress {
    description = "Limit traffic to Redshift port"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Any traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}redshift-sg"
  }
}

resource "aws_redshift_cluster" "rs_cluster" {
  cluster_identifier        = "${var.name_prefix}${var.rs_cluster_name}"
  database_name             = var.rs_database_name
  master_username           = var.rs_master_username
  master_password           = var.rs_master_pass
  node_type                 = var.rs_node_type
  cluster_type              = var.rs_cluster_type
  skip_final_snapshot       = true
  iam_roles                 = [var.iam_role_arn]
  cluster_subnet_group_name = aws_redshift_subnet_group.rs_subnet_group.id

  publicly_accessible  = false
  enhanced_vpc_routing = true

  depends_on = [
    aws_default_security_group.rs_security_group,
    aws_redshift_subnet_group.rs_subnet_group,
  ]
}
