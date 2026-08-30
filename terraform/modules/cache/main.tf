locals {
  common_tags = merge(
    var.common_tags,
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Layer       = "Cache"
    }
  )
}

# =========================================================
# REDIS SUBNET GROUP
# =========================================================

resource "aws_elasticache_subnet_group" "redis" {
  name = "${var.project_name}-${var.environment}-redis-subnet-group"

  subnet_ids = var.private_app_subnet_ids

  description = "Private subnet group for ${var.project_name} Redis"

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-redis-subnet-group"
    }
  )
}

# =========================================================
# REDIS PARAMETER GROUP
# =========================================================

resource "aws_elasticache_parameter_group" "redis" {
  name = "${var.project_name}-${var.environment}-redis-params"

  family = var.parameter_group_family

  description = "Redis parameter group for ${var.project_name}"

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-redis-params"
    }
  )
}

# =========================================================
# REDIS REPLICATION GROUP
# =========================================================

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = "${var.project_name}-${var.environment}-redis"

  description = "Redis cache for ${var.project_name} ${var.environment}"

  engine = "redis"

  engine_version = var.redis_engine_version

  node_type = var.redis_node_type

  port = var.redis_port

  num_cache_clusters = var.redis_num_cache_nodes

  parameter_group_name = aws_elasticache_parameter_group.redis.name

  subnet_group_name = aws_elasticache_subnet_group.redis.name

  security_group_ids = [
    var.redis_security_group_id
  ]

  automatic_failover_enabled = var.automatic_failover_enabled

  multi_az_enabled = var.multi_az_enabled

  transit_encryption_enabled = var.transit_encryption_enabled

  at_rest_encryption_enabled = var.at_rest_encryption_enabled

  kms_key_id = var.kms_key_id

  snapshot_retention_limit = var.snapshot_retention_limit

  snapshot_window = var.snapshot_window

  maintenance_window = var.maintenance_window

  apply_immediately = var.apply_immediately

  auto_minor_version_upgrade = true

  notification_topic_arn = null

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-redis"
    }
  )
}
