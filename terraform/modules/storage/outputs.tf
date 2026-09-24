output "downloads_bucket_name" {
  description = "Invoice downloads bucket name"
  value       = aws_s3_bucket.downloads.bucket
}

output "downloads_bucket_arn" {
  description = "Invoice downloads bucket ARN"
  value       = aws_s3_bucket.downloads.arn
}

output "downloads_bucket_regional_domain_name" {
  description = "Regional domain name, for use as a CloudFront origin"
  value       = aws_s3_bucket.downloads.bucket_regional_domain_name
}

output "static_bucket_name" {
  description = "Static web UI assets bucket name"
  value       = aws_s3_bucket.static.bucket
}

output "static_bucket_arn" {
  description = "Static assets bucket ARN"
  value       = aws_s3_bucket.static.arn
}

output "static_bucket_regional_domain_name" {
  description = "Regional domain name, for use as a CloudFront origin"
  value       = aws_s3_bucket.static.bucket_regional_domain_name
}

output "logs_bucket_name" {
  description = "Audit/access logs bucket name"
  value       = aws_s3_bucket.logs.bucket
}

output "logs_bucket_arn" {
  description = "Logs bucket ARN"
  value       = aws_s3_bucket.logs.arn
}

output "downloads_dr_bucket_name" {
  description = "DR replica of the downloads bucket, or null if replication is disabled"
  value       = var.enable_dr_replication ? aws_s3_bucket.downloads_dr[0].bucket : null
}
