locals {
  common_tags = merge(
    var.common_tags,
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Layer       = "Database"
    }
  )
}

resource "aws_db_subnet_group" "primary" {
  provider = aws.primary

  name = "${var.project_name}-${var.environment}-db-primary"

  subnet_ids = var.private_db_subnet_ids

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-db-primary"
    }
  )
}

resource "aws_rds_global_cluster" "archvault_global" {
  provider = aws.primary

  global_cluster_identifier = "${var.project_name}-${var.environment}-global"

  engine         = "aurora-postgresql"
  engine_version = var.database_engine_version

  database_name = var.database_name

  storage_encrypted = true

  deletion_protection = false

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-global"
    }
  )
}

resource "aws_rds_cluster" "primary" {
  provider = aws.primary

  cluster_identifier = "${var.project_name}-${var.environment}-primary"

  engine         = "aurora-postgresql"
  engine_version = var.database_engine_version

  global_cluster_identifier = aws_rds_global_cluster.archvault_global.id

  database_name   = var.database_name
  master_username = var.database_username

  db_subnet_group_name   = aws_db_subnet_group.primary.name
  vpc_security_group_ids = [var.database_security_group_id]

  storage_encrypted = true
  kms_key_id        = var.database_kms_key_arn

  backup_retention_period = var.backup_retention_period

  preferred_backup_window    = "03:00-04:00"
  preferred_maintenance_window = "sun:04:00-sun:05:00"

  deletion_protection = false
  skip_final_snapshot = true

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-primary-cluster"
    }
  )
}

resource "aws_rds_cluster_instance" "primary" {
  provider = aws.primary

  count = var.primary_instance_count

  identifier = "${var.project_name}-${var.environment}-primary-${count.index}"

  cluster_identifier = aws_rds_cluster.primary.id

  instance_class = var.database_instance_class
  engine         = aws_rds_cluster.primary.engine

  publicly_accessible = false

  auto_minor_version_upgrade = true

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-primary-${count.index}"
    }
  )
}
