output "database_id" {
  description = "RDS database identifier"
  value       = aws_db_instance.this.id
}

output "database_arn" {
  description = "RDS database ARN"
  value       = aws_db_instance.this.arn
}

output "database_endpoint" {
  description = "RDS database endpoint"
  value       = aws_db_instance.this.address
}

output "database_port" {
  description = "RDS database port"
  value       = aws_db_instance.this.port
}

output "database_name" {
  description = "Database name"
  value       = aws_db_instance.this.db_name
}
