output "data_transformer_sqs_arn" {
  description = "ARN of SQS that will trigger data_transformer"
  value       = aws_sqs_queue.data_transformer_sqs.arn
}

output "data_copier_sqs_arn" {
  description = "ARN of SQS that will trigger data_copier"
  value       = aws_sqs_queue.data_copier_sqs.arn
}

output "data_dest_bucket_id" {
  description = "S3 bucket ID where data is stored"
  value       = aws_s3_bucket.data_bucket.id
}

output "error_alert_sns_topic_arn" {
  description = "SNS topic ARN for alerting an error in lambdas"
  value       = aws_sns_topic.error_alert_sns_topic.arn
}