output "bucket_id" {
  description = "Primary S3 bucket ID"
  value       = aws_s3_bucket.primary.id
}

output "bucket_arn" {
  description = "Primary S3 bucket ARN"
  value       = aws_s3_bucket.primary.arn
}
