<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | n/a |
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 4.0 |

## Modules

No modules.

## Resources

| Name | Type | Description |
|------|------|------|
| [aws_cloudwatch_metric_alarm.rs_loader_error_alarm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource | CloudWatch Alarm that triggers *error_alert_sns_topic* when error message is logged by the *rs_loader* Lambda |
| [aws_lambda_event_source_mapping.trigger_rs_loader](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_event_source_mapping) | resource | Set the *rs_loader* SQS as a trigger for the *rs_loader* Lambda |
| [aws_lambda_function.rs_loader](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource | Function that subscribes to the *rs_loader* SQS and copies data to a Redshift table |
| [archive_file.lambda_package](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source | Package Lambda source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source | Current AWS region |
| [aws_vpc.selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source | Selected VPC |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_error_alert_sns_topic_arn"></a> [error\_alert\_sns\_topic\_arn](#input\_error\_alert\_sns\_topic\_arn) | SNS topic ARN for alerting an error in lambdas | `string` | n/a | yes |
| <a name="input_lambda_layer_arn"></a> [lambda\_layer\_arn](#input\_lambda\_layer\_arn) | ARN of the Lambda dependency layer | `string` | n/a | yes |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix for named resources | `string` | `""` | no |
| <a name="input_rs_cluster_dns_name"></a> [rs\_cluster\_dns\_name](#input\_rs\_cluster\_dns\_name) | DNS name of Redshift cluster | `string` | n/a | yes |
| <a name="input_rs_database_name"></a> [rs\_database\_name](#input\_rs\_database\_name) | Database name to load the data | `string` | n/a | yes |
| <a name="input_rs_execution_role_arn"></a> [rs\_execution\_role\_arn](#input\_rs\_execution\_role\_arn) | IAM role ARN that can access Redshift from lambda | `string` | n/a | yes |
| <a name="input_rs_loader_sqs_arn"></a> [rs\_loader\_sqs\_arn](#input\_rs\_loader\_sqs\_arn) | ARN of the SQS that will be a trigger for the Lambda | `string` | n/a | yes |
| <a name="input_rs_master_pass"></a> [rs\_master\_pass](#input\_rs\_master\_pass) | Redshift password | `string` | n/a | yes |
| <a name="input_rs_master_username"></a> [rs\_master\_username](#input\_rs\_master\_username) | Redshift username | `string` | n/a | yes |
| <a name="input_rs_schema"></a> [rs\_schema](#input\_rs\_schema) | Redshift schema name | `string` | n/a | yes |
| <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids) | Redshift security group ids | `list(string)` | n/a | yes |
| <a name="input_staging_bucket"></a> [staging\_bucket](#input\_staging\_bucket) | Bucket in which the data is stored. | `string` | n/a | yes |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | list of subnets | `list(string)` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->