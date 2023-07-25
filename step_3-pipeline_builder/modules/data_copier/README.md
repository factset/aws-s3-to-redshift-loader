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
| [aws_cloudwatch_metric_alarm.data_copier_error_alarm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource | CloudWatch Alarm that triggers the *error_alert_sns_topic* when error message is logged by the *data_copier* Lambda |
| [aws_lambda_event_source_mapping.trigger_data_copier_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_event_source_mapping) | resource | Set the *data_copier* SQS as a trigger for the *data_copier* Lambda |
| [aws_lambda_function.data_copier](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource | Function that subscribes to the *data_copier* SQS, copies data, and publishes a message to the *data_transformer* SQS |
| [aws_s3_bucket.data_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource | Destination where data is copied to |
| [aws_sns_topic.error_alert_sns_topic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |  SNS topic that sends out an email when triggered |
| [aws_sns_topic_subscription.data_copier_sqs_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource | The *data_copier*'s subscription to data provider's SNS topic |
| [aws_sns_topic_subscription.error_alert_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource | The *data_copier_error_alarm*'s subscription to the *error_alert_sns_topic* |
| [aws_sqs_queue.data_copier_sqs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource | Queue system that subscribes to the data provider's SNS topic and keeps the messages in order |
| [aws_sqs_queue.data_transformer_sqs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource | Queue system to which *data_copier* Lambda publishes a message at the end of the process |
| [null_resource.pip_install](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [archive_file.lambda_package](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source | Package build directory |
| [aws_iam_policy_document.sqs_policy_doc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source | SQS policy |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source | Current AWS region |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_data_bucket_name"></a> [data\_bucket\_name](#input\_data\_bucket\_name) | (Required) Destination bucket in which the data will be copied to | `string` | n/a | yes |
| <a name="input_data_source_access_point_alias"></a> [data\_source\_access\_point\_alias](#input\_data\_source\_access\_point\_alias) | (Required) Data Source's S3 Access Point ARN | `string` | n/a | yes |
| <a name="input_data_source_aws_region"></a> [data\_source\_aws\_region](#input\_data\_source\_aws\_region) | (Required) AWS region in which data source's bucket is in | `string` | n/a | yes |
| <a name="input_email_alert_recipient"></a> [email\_alert\_recipient](#input\_email\_alert\_recipient) | Email address that will recieve an error alert | `string` | n/a | yes |
| <a name="input_iam_role_arn"></a> [iam\_role\_arn](#input\_iam\_role\_arn) | (Required) ARN of the AWS Data Delivery Role | `string` | n/a | yes |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix for named resources | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_data_copier_sqs_arn"></a> [data\_copier\_sqs\_arn](#output\_data\_copier\_sqs\_arn) | ARN of SQS that will trigger data\_copier |
| <a name="output_data_dest_bucket_id"></a> [data\_dest\_bucket\_id](#output\_data\_dest\_bucket\_id) | S3 bucket ID where data is stored |
| <a name="output_data_transformer_sqs_arn"></a> [data\_transformer\_sqs\_arn](#output\_data\_transformer\_sqs\_arn) | ARN of SQS that will trigger data\_transformer |
| <a name="output_error_alert_sns_topic_arn"></a> [error\_alert\_sns\_topic\_arn](#output\_error\_alert\_sns\_topic\_arn) | SNS topic ARN for alerting an error in lambdas |
<!-- END_TF_DOCS -->