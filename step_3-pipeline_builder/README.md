<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_data_copier"></a> [data\_copier](#module\_data\_copier) | ./modules/data_copier | n/a |
| <a name="module_data_transformer"></a> [data\_transformer](#module\_data\_transformer) | ./modules/data_transformer | n/a |
| <a name="module_redshift_loader"></a> [redshift\_loader](#module\_redshift\_loader) | ./modules/redshift_loader | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | AWS credential profile | `string` | `""` | no |
| <a name="input_data_bucket_name"></a> [data\_bucket\_name](#input\_data\_bucket\_name) | (Required) Destination bucket in which the data will be copied to | `string` | n/a | yes |
| <a name="input_data_destination_aws_region"></a> [data\_destination\_aws\_region](#input\_data\_destination\_aws\_region) | (Required) AWS region in which data destination's bucket is in | `string` | n/a | yes |
| <a name="input_data_source_access_point_alias"></a> [data\_source\_access\_point\_alias](#input\_data\_source\_access\_point\_alias) | (Required) Data Source's S3 Access Point ARN | `string` | n/a | yes |
| <a name="input_data_source_aws_region"></a> [data\_source\_aws\_region](#input\_data\_source\_aws\_region) | (Required) AWS region in which data source's bucket is in | `string` | n/a | yes |
| <a name="input_email_alert_recipient"></a> [email\_alert\_recipient](#input\_email\_alert\_recipient) | Email address that will recieve an error alert | `string` | n/a | yes |
| <a name="input_iam_role_arn"></a> [iam\_role\_arn](#input\_iam\_role\_arn) | (Required) ARN of the AWS Data Delivery Role | `string` | n/a | yes |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix for named resources | `string` | `""` | no |
| <a name="input_rs_cluster_dns_name"></a> [rs\_cluster\_dns\_name](#input\_rs\_cluster\_dns\_name) | (Required) DNS name of the Redshift cluster | `string` | n/a | yes |
| <a name="input_rs_database_name"></a> [rs\_database\_name](#input\_rs\_database\_name) | Database name to load the data | `string` | n/a | yes |
| <a name="input_rs_execution_role_arn"></a> [rs\_execution\_role\_arn](#input\_rs\_execution\_role\_arn) | ARN of the RedShift execution role | `string` | `""` | no |
| <a name="input_rs_master_pass"></a> [rs\_master\_pass](#input\_rs\_master\_pass) | Redshift password | `string` | n/a | yes |
| <a name="input_rs_master_username"></a> [rs\_master\_username](#input\_rs\_master\_username) | Redshift username | `string` | n/a | yes |
| <a name="input_rs_schema"></a> [rs\_schema](#input\_rs\_schema) | Redshift schema name | `string` | `"public"` | no |
| <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids) | Redshift security group ids | `list(string)` | n/a | yes |
| <a name="input_staging_bucket_name"></a> [staging\_bucket\_name](#input\_staging\_bucket\_name) | Bucket in which the data will be stored temporarily for processing. | `string` | n/a | yes |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | list of subnets | `list(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_data_copier_sqs_arn"></a> [data\_copier\_sqs\_arn](#output\_data\_copier\_sqs\_arn) | ARN of the Data Copier SQS |
<!-- END_TF_DOCS -->