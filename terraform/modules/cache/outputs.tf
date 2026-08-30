output "redis_replication_group_id" {
  description = "ID of the Redis replication group."
  value       = aws_elasticache_replication_group.redis.id
}

output "redis_replication_group_arn" {
  description = "ARN of the Redis replication group."
  value       = aws_elasticache_replication_group.redis.arn
}

output "redis_primary_endpoint_address" {
  description = "Primary Redis endpoint address."
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "redis_primary_endpoint_port" {
  description = "Primary Redis endpoint port."
  value       = aws_elasticache_replication_group.redis.port
}

output "redis_reader_endpoint_address" {
  description = "Redis reader endpoint address."
  value       = aws_elasticache_replication_group.redis.reader_endpoint_address
}

output "redis_configuration_endpoint_address" {
  description = "Redis configuration endpoint address."
  value       = aws_elasticache_replication_group.redis.configuration_endpoint_address
}

output "redis_subnet_group_name" {
  description = "Name of the Redis subnet group."
  value       = aws_elasticache_subnet_group.redis.name
}

output "redis_parameter_group_name" {
  description = "Name of the Redis parameter group."
  value       = aws_elasticache_parameter_group.redis.name
}
