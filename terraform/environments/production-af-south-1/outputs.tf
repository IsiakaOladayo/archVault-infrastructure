output "project_name" {
  description = "ArchVault project name."
  value       = var.project_name
}

output "environment" {
  description = "Deployment environment."
  value       = var.environment
}

output "primary_region" {
  description = "ArchVault primary AWS region."
  value       = var.primary_region
}

output "vpc_id" {
  description = "ArchVault VPC ID."
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "ArchVault public subnet IDs."
  value       = module.networking.public_subnet_ids
}

output "private_app_subnet_ids" {
  description = "ArchVault private application subnet IDs."
  value       = module.networking.private_app_subnet_ids
}

output "private_db_subnet_ids" {
  description = "ArchVault private database subnet IDs."
  value       = module.networking.private_db_subnet_ids
}

output "database_kms_key_arn" {
  description = "KMS key ARN for database encryption."
  value       = module.security.database_kms_key_arn
}

output "documents_kms_key_arn" {
  description = "KMS key ARN for S3 document encryption."
  value       = module.security.documents_kms_key_arn
}

output "secrets_kms_key_arn" {
  description = "KMS key ARN for Secrets Manager encryption."
  value       = module.security.secrets_kms_key_arn
}
