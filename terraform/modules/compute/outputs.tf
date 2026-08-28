output "alb_arn" {
  description = "Application Load Balancer ARN"
  value       = aws_lb.application.arn
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = aws_lb.application.dns_name
}

output "alb_zone_id" {
  description = "Application Load Balancer hosted zone ID"
  value       = aws_lb.application.zone_id
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.application.name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.application.name
}
