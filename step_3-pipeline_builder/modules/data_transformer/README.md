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
| <a name="provider_null"></a> [null](#provider\_null) | n/a |

## Modules

No modules.

## Resources

| Name | Type | Description |
|------|------|------|
| [aws_cloudwatch_metric_alarm.data_transformer_error_alarm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource | CloudWatch Alarm that triggers the *error_alert_sns_topic* when error message is logged by the *data_transformer* Lambda |
| [aws_lambda_event_source_mapping.trigger_data_transformer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_event_source_mapping) | resource | Set the *data_transformer* SQS as a trigger for the *data_transformer* Lambda |
| [aws_lambda_function.data_transformer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource | Function that subscribes to the *data_transformer* SQS, prepares data to be loaded into Redshift, and publishes a message to *rs_loader* SQS |
| [aws_lambda_layer_version.layer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_layer_version) | resource | Lambda layer with dependencies |
| [aws_s3_bucket.data_transformer_lambda_package](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource | S3 bucket to store the *data_transformer* Lambda package |
| [aws_s3_bucket.staging_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource | S3 bucket to store temporary gzip data files until they are copied into Redshift |
| [aws_s3_object.layer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource | S3 object of the *data_transformer* Lambda layer |
| [aws_sqs_queue.rs_loader_sqs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource | Queue system to which the *data_transformer* Lambda publishes a message at the end of the process |
| [null_resource.pip_install](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource | Install dependencies of the *data_transformer* Lambda |
| [archive_file.lambda_package](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source | Package Lambda source |
| [archive_file.layer](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source | Package Lambda layer |
| [aws_iam_policy_document.sqs_policy_doc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source | SQS policy |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source | Current AWS region |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_data_src_bucket_id"></a> [data\_src\_bucket\_id](#input\_data\_src\_bucket\_id) | Bucket in which the data is stored. | `string` | n/a | yes |
| <a name="input_data_transformer_sqs_arn"></a> [data\_transformer\_sqs\_arn](#input\_data\_transformer\_sqs\_arn) | SQS ARN that data\_transformer lambda will subscribe to | `string` | n/a | yes |
| <a name="input_error_alert_sns_topic_arn"></a> [error\_alert\_sns\_topic\_arn](#input\_error\_alert\_sns\_topic\_arn) | SNS topic ARN for alerting an error in lambdas | `string` | n/a | yes |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix for named resources | `string` | `""` | no |
| <a name="input_rs_cluster_dns_name"></a> [rs\_cluster\_dns\_name](#input\_rs\_cluster\_dns\_name) | DNS name of the Redshift cluster | `string` | n/a | yes |
| <a name="input_rs_database_name"></a> [rs\_database\_name](#input\_rs\_database\_name) | Database name to load the data | `string` | n/a | yes |
| <a name="input_rs_execution_role_arn"></a> [rs\_execution\_role\_arn](#input\_rs\_execution\_role\_arn) | IAM role ARN that can access Redshift from lambda | `string` | n/a | yes |
| <a name="input_rs_master_pass"></a> [rs\_master\_pass](#input\_rs\_master\_pass) | Redshift password | `string` | n/a | yes |
| <a name="input_rs_master_username"></a> [rs\_master\_username](#input\_rs\_master\_username) | Redshift username | `string` | n/a | yes |
| <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids) | Redshift security group ids | `list(string)` | n/a | yes |
| <a name="input_staging_bucket_name"></a> [staging\_bucket\_name](#input\_staging\_bucket\_name) | Bucket in which the data will be stored temporarily for processing. | `string` | n/a | yes |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | list of subnets | `list(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_lambda_layer_arn"></a> [lambda\_layer\_arn](#output\_lambda\_layer\_arn) | ARN of the Lambda layer |
| <a name="output_rs_loader_sqs_arn"></a> [rs\_loader\_sqs\_arn](#output\_rs\_loader\_sqs\_arn) | ARN of the rs\_loader SQS |
| <a name="output_staging_bucket"></a> [staging\_bucket](#output\_staging\_bucket) | S3 bucket for staging data |
<!-- END_TF_DOCS -->