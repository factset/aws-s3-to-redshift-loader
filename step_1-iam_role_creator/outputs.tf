output "iam_role_arn" {
  description = "ARN of newly created role for AWS data delivery process. Please share this value with the data source."
  value       = aws_iam_role.aws_data_delivery_role.arn
}
