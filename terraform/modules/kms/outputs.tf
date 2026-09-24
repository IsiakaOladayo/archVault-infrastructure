output "database_kms_key_arn" {
  description = "ARN of the primary-region Aurora CMK"
  value       = aws_kms_key.database.arn
}

output "database_kms_key_id" {
  description = "Key ID of the primary-region Aurora CMK"
  value       = aws_kms_key.database.key_id
}

output "database_kms_key_dr_arn" {
  description = "ARN of the DR-region (eu-west-1) Aurora replica CMK — Zero Knowledge Storage"
  value       = aws_kms_replica_key.database_dr.arn
}

output "documents_kms_key_primary_arn" {
  description = "ARN of the primary-region S3 documents/invoices CMK"
  value       = aws_kms_key.documents.arn
}

output "documents_kms_key_dr_arn" {
  description = "ARN of the DR-region S3 documents replica CMK, or null if cross-region document replication is not enabled"
  value       = var.enable_documents_dr_replication ? aws_kms_replica_key.documents_dr[0].arn : null
}

output "logs_kms_key_arn" {
  description = "ARN of the S3 logs CMK"
  value       = aws_kms_key.logs.arn
}

output "secrets_kms_key_arn" {
  description = "ARN of the Secrets Manager CMK"
  value       = aws_kms_key.secrets.arn
}
