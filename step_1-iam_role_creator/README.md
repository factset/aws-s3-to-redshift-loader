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
| [aws_iam_role.aws_data_delivery_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource | IAM role for receiving the data provider's SNS message and copying their S3 objects |
| [aws_iam_role_policy.aws_data_delivery_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource | IAM role policy that allows the role to access the data provider's resources |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source | Current AWS caller ID |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_iam_role_name"></a> [iam\_role\_name](#input\_iam\_role\_name) | Name of the IAM role | `string` | n/a | yes |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix for named resources | `string` | `""` | no |
| <a name="input_data_destination_aws_region"></a> [data\_destination\_aws\_region](#input\_data\_destination\_aws\_region) | AWS region in which data destination's bucket is in | `string` | n/a | yes |
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | AWS credential profile | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_iam_role_arn"></a> [iam\_role\_arn](#output\_iam\_role\_arn) | ARN of newly created role for AWS data delivery process. Please share this value with the data source. |
<!-- END_TF_DOCS -->