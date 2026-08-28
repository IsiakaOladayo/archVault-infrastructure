output "project_name" {
  description = "ArchVault project name"
  value       = var.project_name
}

output "environment" {
  description = "Deployment environment"
  value       = var.environment
}

output "primary_region" {
  description = "Primary AWS region"
  value       = var.primary_region
}

output "vpc_id" {
  description = "ArchVault VPC ID"
  value       = module.networking.vpc_id
}

output "vpc_cidr" {
  description = "ArchVault VPC CIDR"
  value       = module.networking.vpc_cidr
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.networking.public_subnet_ids
}

output "private_app_subnet_ids" {
  description = "Private application subnet IDs"
  value       = module.networking.private_app_subnet_ids
}

output "private_db_subnet_ids" {
  description = "Private database subnet IDs"
  value       = module.networking.private_db_subnet_ids
}

output "nat_gateway_ids" {
  description = "NAT Gateway IDs"
  value       = module.networking.nat_gateway_ids
}
