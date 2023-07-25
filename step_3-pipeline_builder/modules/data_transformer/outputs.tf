output "lambda_layer_arn" {
  description = "ARN of the Lambda layer"
  value       = aws_lambda_layer_version.layer.arn
}

output "rs_loader_sqs_arn" {
  description = "ARN of the rs_loader SQS"
  value       = aws_sqs_queue.rs_loader_sqs.arn
}

output "staging_bucket" {
  description = "S3 bucket for staging data"
  value       = aws_s3_bucket.staging_bucket.id
}