# Subnet Group for Cache placement in Tier 3 Isolated Subnets
resource "aws_elasticache_subnet_group" "redis_subnets" {
  name        = "archvault-redis-subnet-group"
  subnet_ids  = var.isolated_subnet_ids
  description = "Subnet group for ArchVault ElastiCache Redis in Tier 3 isolated network"
}

# Security Group restricting inbound traffic to Redis (Port 6379) strictly from Tier 2 ECS tasks
resource "aws_security_group" "redis_sg" {
  name        = "archvault-redis-sg"
  description = "Allow inbound Redis traffic from Tier 2 ECS application tasks only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Redis from ECS Fargate tasks"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [var.ecs_security_group_id]
  }

  egress {
    description = "Disallow outbound connections"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "archvault-redis-sg"
  }
}

# Multi-AZ ElastiCache Redis Replication Group
resource "aws_elasticache_replication_group" "redis" {
  replication_group_id          = "archvault-redis-cluster"
  description                   = "High-availability multi-AZ Redis cache for Aurora read offloading"
  node_type                     = "cache.r6g.large"
  num_cache_clusters            = 3 # 1 Primary, 2 Read Replicas across 3 AZs
  port                          = 6379
  automatic_failover_enabled    = true
  multi_az_enabled              = true
  subnet_group_name             = aws_elasticache_subnet_group.redis_subnets.name
  security_group_ids            = [aws_security_group.redis_sg.id]
  engine                        = "redis"
  engine_version                = "7.0"
  parameter_group_name          = "default.redis7"

  # Encryption & Security Compliance
  at_rest_encryption_enabled    = true
  transit_encryption_enabled   = true
  kms_key_id                    = var.kms_key_arn

  tags = {
    Name        = "archvault-redis-cluster"
    Environment = "Production"
  }
}
