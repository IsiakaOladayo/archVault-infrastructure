output "alb_security_group_id" {
  description = "Security group ID for the ALB"
  value       = aws_security_group.alb.id
}

output "application_security_group_id" {
  description = "Security group ID for ECS application tasks"
  value       = aws_security_group.ecs.id
}

output "database_security_group_id" {
  description = "Security group ID for the primary Aurora cluster"
  value       = aws_security_group.database.id
}

output "dr_database_security_group_id" {
  description = "Security group ID for the DR Aurora cluster (eu-west-1)"
  value       = aws_security_group.database_dr.id
}

output "redis_security_group_id" {
  description = "Security group ID for ElastiCache Redis"
  value       = aws_security_group.redis.id
}

output "ecs_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_execution.arn
}

output "ecs_execution_role_name" {
  description = "Name of the ECS task execution role"
  value       = aws_iam_role.ecs_execution.name
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS application task role"
  value       = aws_iam_role.ecs_task.arn
}

output "ecs_task_role_name" {
  description = "Name of the ECS application task role"
  value       = aws_iam_role.ecs_task.name
}

output "regional_waf_web_acl_arn" {
  description = "ARN of the regional WAF Web ACL, attached to the ALB"
  value       = var.enable_waf ? aws_wafv2_web_acl.regional[0].arn : null
}

output "cloudfront_waf_web_acl_arn" {
  description = "ARN of the CloudFront-scoped WAF Web ACL"
  value       = var.enable_waf ? aws_wafv2_web_acl.cloudfront[0].arn : null
}
