output "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.application.id
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.application.arn
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.application.name
}

output "ecs_task_definition_arn" {
  description = "ARN of the ECS task definition"
  value       = aws_ecs_task_definition.application.arn
}

output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution.arn
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS application task role"
  value       = aws_iam_role.ecs_task.arn
}

output "alb_id" {
  description = "ID of the Application Load Balancer"
  value       = aws_lb.application.id
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.application.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.application.dns_name
}

output "target_group_arn" {
  description = "ARN of the ECS target group"
  value       = aws_lb_target_group.application.arn
}

output "cloudwatch_log_group_name" {
  description = "Application CloudWatch log group"
  value       = aws_cloudwatch_log_group.application.name
}
