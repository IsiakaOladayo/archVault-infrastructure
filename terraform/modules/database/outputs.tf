output "global_cluster_id" {
  description = "ID of the Aurora Global Database cluster"
  value       = aws_rds_global_cluster.archvault_global.id
}

output "primary_cluster_id" {
  description = "ID of the primary Aurora cluster (af-south-1)"
  value       = aws_rds_cluster.primary.id
}

output "primary_cluster_arn" {
  description = "ARN of the primary Aurora cluster"
  value       = aws_rds_cluster.primary.arn
}

output "primary_cluster_endpoint" {
  description = "Writer endpoint of the primary Aurora cluster"
  value       = aws_rds_cluster.primary.endpoint
}

output "primary_cluster_reader_endpoint" {
  description = "Reader endpoint of the primary Aurora cluster"
  value       = aws_rds_cluster.primary.reader_endpoint
}

output "primary_master_secret_arn" {
  description = "Secrets Manager ARN holding the primary cluster's master credentials"
  value       = aws_rds_cluster.primary.master_user_secret[0].secret_arn
}

output "secondary_cluster_id" {
  description = "ID of the secondary (DR) Aurora cluster (eu-west-1)"
  value       = aws_rds_cluster.secondary.id
}

output "secondary_cluster_endpoint" {
  description = "Endpoint of the secondary Aurora cluster"
  value       = aws_rds_cluster.secondary.endpoint
}

output "rds_proxy_endpoint" {
  description = "Endpoint of the RDS Proxy in front of the primary cluster"
  value       = aws_db_proxy.primary.endpoint
}

output "rds_proxy_arn" {
  description = "ARN of the RDS Proxy"
  value       = aws_db_proxy.primary.arn
}

output "alb_arn_suffix" {
  description = "ARN suffix of the ALB, used for CloudWatch metric dimensions"
  value       = aws_lb.application.arn_suffix
}
