output "alb_security_group_id" {
  description = "Security group ID for the Application Load Balancer"
  value       = aws_security_group.alb.id
}

output "ecs_security_group_id" {
  description = "Security group ID for ECS Fargate tasks"
  value       = aws_security_group.ecs.id
}

output "database_security_group_id" {
  description = "Security group ID for Aurora PostgreSQL"
  value       = aws_security_group.database.id
}

output "redis_security_group_id" {
  description = "Security group ID for Redis"
  value       = aws_security_group.redis.id
}

output "database_kms_key_arn" {
  description = "ARN of the customer-managed database KMS key"
  value       = aws_kms_key.database.arn
}

output "database_kms_key_id" {
  description = "ID of the customer-managed database KMS key"
  value       = aws_kms_key.database.key_id
}

output "documents_kms_key_arn" {
  description = "ARN of the customer-managed documents KMS key"
  value       = aws_kms_key.documents.arn
}

output "documents_kms_key_id" {
  description = "ID of the customer-managed documents KMS key"
  value       = aws_kms_key.documents.key_id
}

output "secrets_kms_key_arn" {
  description = "ARN of the customer-managed secrets KMS key"
  value       = aws_kms_key.secrets.arn
}

output "secrets_kms_key_id" {
  description = "ID of the customer-managed secrets KMS key"
  value       = aws_kms_key.secrets.key_id
}

output "ecs_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_execution.arn
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS application task role"
  value       = aws_iam_role.ecs_task.arn
}

output "waf_web_acl_arn" {
  description = "ARN of the WAF Web ACL"
  value       = var.enable_waf ? aws_wafv2_web_acl.application[0].arn : null
}

output "waf_web_acl_id" {
  description = "ID of the WAF Web ACL"
  value       = var.enable_waf ? aws_wafv2_web_acl.application[0].id : null
}

output "documents_kms_key_primary_arn" {
  description = "ARN of the primary-region document encryption KMS key"
  value       = aws_kms_key.documents_primary.arn
}

output "documents_kms_key_dr_arn" {
  description = "ARN of the DR-region document encryption KMS key"
  value       = aws_kms_key.documents_dr.arn
}

output "documents_kms_key_primary_id" {
  description = "ID of the primary-region document encryption KMS key"
  value       = aws_kms_key.documents_primary.key_id
}

output "documents_kms_key_dr_id" {
  description = "ID of the DR-region document encryption KMS key"
  value       = aws_kms_key.documents_dr.key_id
}
