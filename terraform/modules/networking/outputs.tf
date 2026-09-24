output "vpc_id" {
  description = "ID of the ArchVault VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_app_subnet_ids" {
  description = "IDs of the private application subnets"
  value       = aws_subnet.private_app[*].id
}

output "private_db_subnet_ids" {
  description = "IDs of the private database subnets"
  value       = aws_subnet.private_db[*].id
}

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways"
  value       = aws_nat_gateway.main[*].id
}

output "availability_zones" {
  description = "Availability Zones used by the network"
  value       = var.availability_zones
}

output "nat_gateway_id" {
  description = "ID of the single regional NAT Gateway (null if disabled)"
  value       = var.enable_nat_gateway ? aws_nat_gateway.main[0].id : null
}

output "flow_log_group_name" {
  description = "CloudWatch log group receiving VPC Flow Logs"
  value       = aws_cloudwatch_log_group.flow_logs.name
}

output "dr_vpc_id" {
  description = "ID of the DR-region VPC"
  value       = aws_vpc.dr.id
}

output "dr_public_subnet_ids" {
  description = "IDs of the DR public subnets"
  value       = aws_subnet.dr_public[*].id
}

output "dr_private_app_subnet_ids" {
  description = "IDs of the DR private application subnets (pilot-light health-check task)"
  value       = aws_subnet.dr_private_app[*].id
}

output "dr_private_db_subnet_ids" {
  description = "IDs of the DR private database subnets (Aurora secondary cluster)"
  value       = aws_subnet.dr_private_db[*].id
}

output "dr_nat_gateway_id" {
  description = "ID of the DR regional NAT Gateway (null if disabled)"
  value       = var.enable_dr_nat_gateway ? aws_nat_gateway.dr[0].id : null
}
