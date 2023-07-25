<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 4.0 |

## Modules

No modules.

## Resources

| Name | Type | Description |
|------|------|------|
| [aws_default_security_group.rs_security_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_security_group) | resource | Redshift security group |
| [aws_redshift_cluster.rs_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/redshift_cluster) | resource | Redshift cluster |
| [aws_redshift_subnet_group.rs_subnet_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/redshift_subnet_group) | resource | Redshift subnet group |
| [aws_vpc.selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source | Selected VPC |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix for named resources | `string` | `""` | no |
| <a name="input_iam_role_arn"></a> [iam\_role\_arn](#input\_name\_prefix) | ARN of IAM role | `string` | n/a | yes |
| <a name="input_rs_cluster_name"></a> [rs\_cluster\_name](#input\_rs\_cluster\_name) | Name of the Redshift cluster | `string` | n/a | yes |
| <a name="input_rs_cluster_type"></a> [rs\_cluster\_type](#input\_rs\_cluster\_type) | Redshift cluster type. Either single-node or multi-node | `string` | n/a | yes |
| <a name="input_rs_database_name"></a> [rs\_database\_name](#input\_rs\_database\_name) | Database name to load the data | `string` | n/a | yes |
| <a name="input_rs_master_pass"></a> [rs\_master\_pass](#input\_rs\_master\_pass) | Redshift password | `string` | n/a | yes |
| <a name="input_rs_master_username"></a> [rs\_master\_username](#input\_rs\_master\_username) | Redshift username | `string` | n/a | yes |
| <a name="input_rs_node_type"></a> [rs\_node\_type](#input\_rs\_node\_type) | Redshift node type | `string` | n/a | yes |
| <a name="input_rs_subnet_group_name"></a> [rs\_subnet\_group\_name](#input\_rs\_subnet\_group\_name) | Redshift subnet group name | `string` | n/a | yes |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | List of subnets | `list(string)` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID | `string` | n/a | yes |
| <a name="input_data_destination_aws_region"></a> [data\_destination\_aws\_region](#input\_data\_destination\_aws\_region) | AWS region in which data destination's bucket is in | `string` | n/a | yes |
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | AWS credential profile | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_rs_cluster_dns_name"></a> [rs\_cluster\_dns\_name](#output\_rs\_cluster\_dns\_name) | DNS name of the Redshift cluster |
| <a name="output_security_group_ids"></a> [security\_group\_ids](#output\_security\_group\_ids) | IDs of the Redshift security group |
<!-- END_TF_DOCS -->