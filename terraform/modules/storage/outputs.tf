output "primary_bucket_name" {
  description = "Primary documents bucket"
  value       = aws_s3_bucket.primary.bucket
}

output "primary_bucket_arn" {
  description = "Primary bucket ARN"
  value       = aws_s3_bucket.primary.arn
}

output "replica_bucket_name" {
  description = "Replica bucket name"
  value       = aws_s3_bucket.replica.bucket
}

output "replica_bucket_arn" {
  description = "Replica bucket ARN"
  value       = aws_s3_bucket.replica.arn
}
