<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.67.0 |

## Modules

No modules.

## Resources

| Name | Type | Description |
|------|------|------|
| [aws_sns_topic_subscription.data_copier_sqs_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource | Subscription to the data source's SNS topic |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | AWS credential profile | `string` | `""` | no |
| <a name="input_data_copier_sqs_arn"></a> [data\_copier\_sqs\_arn](#input\_data\_copier\_sqs\_arn) | (Required) ARN of SQS that will trigger data\_copier | `string` | n/a | yes |
| <a name="input_data_source_aws_region"></a> [data\_source\_aws\_region](#input\_data\_source\_aws\_region) | (Required) AWS region in which data source's bucket is in | `string` | n/a | yes |
| <a name="input_data_source_sns_arn"></a> [data\_source\_sns\_arn](#input\_data\_source\_sns\_arn) | (Required) Data Source's SNS ARN to be subscribed by SQS for file notifications | `string` | n/a | yes |
| <a name="input_iam_role_arn"></a> [iam\_role\_arn](#input\_iam\_role\_arn) | ARN of IAM role | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->