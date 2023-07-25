output "data_copier_sqs_arn"{
  description = "ARN of the Data Copier SQS"
  value       = [module.data_copier.data_copier_sqs_arn]
}