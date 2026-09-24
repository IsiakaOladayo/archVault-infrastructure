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

# PRIMARY REGION (af-south-1)

resource "aws_db_subnet_group" "primary" {
  provider = aws.primary

  name       = "${var.project_name}-${var.environment}-db-primary"
  subnet_ids = var.private_db_subnet_ids

  tags = merge(
    local.common_tags,
    { Name = "${var.project_name}-${var.environment}-db-primary" }
  )
}

resource "aws_rds_global_cluster" "archvault_global" {
  provider = aws.primary

  global_cluster_identifier = "${var.project_name}-${var.environment}-global"

  engine         = "aurora-postgresql"
  engine_version = var.database_engine_version

  database_name = var.database_name

  storage_encrypted   = true
  deletion_protection = var.deletion_protection

  tags = merge(
    local.common_tags,
    { Name = "${var.project_name}-${var.environment}-global" }
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

  # Secrets Manager-managed credential (ADR-06) — no plaintext password variable
  manage_master_user_password   = true
  master_user_secret_kms_key_id = var.database_kms_key_arn

  db_subnet_group_name   = aws_db_subnet_group.primary.name
  vpc_security_group_ids = [var.database_security_group_id]

  storage_encrypted = true
  kms_key_id        = var.database_kms_key_arn

  backup_retention_period = var.backup_retention_period

  preferred_backup_window      = "03:00-04:00"
  preferred_maintenance_window = "sun:04:00-sun:05:00"

  deletion_protection = var.deletion_protection
  skip_final_snapshot = true

  tags = merge(
    local.common_tags,
    { Name = "${var.project_name}-${var.environment}-primary-cluster" }
  )
}

resource "aws_rds_cluster_instance" "primary" {
  provider = aws.primary

  count = var.primary_instance_count

  identifier         = "${var.project_name}-${var.environment}-primary-${count.index}"
  cluster_identifier = aws_rds_cluster.primary.id

  instance_class = var.database_instance_class
  engine         = aws_rds_cluster.primary.engine

  publicly_accessible         = false
  auto_minor_version_upgrade  = true

  tags = merge(
    local.common_tags,
    { Name = "${var.project_name}-${var.environment}-primary-${count.index}" }
  )
}

# DR REGION (eu-west-1) — was secondary.tf.bak, now active

resource "aws_db_subnet_group" "secondary" {
  provider = aws.dr

  name       = "${var.project_name}-${var.environment}-db-secondary"
  subnet_ids = var.dr_private_db_subnet_ids

  tags = merge(
    local.common_tags,
    { Name = "${var.project_name}-${var.environment}-db-secondary" }
  )
}

resource "aws_rds_cluster" "secondary" {
  provider = aws.dr

  cluster_identifier = "${var.project_name}-${var.environment}-secondary"

  engine         = "aurora-postgresql"
  engine_version = var.database_engine_version

  global_cluster_identifier = aws_rds_global_cluster.archvault_global.id

  db_subnet_group_name   = aws_db_subnet_group.secondary.name
  vpc_security_group_ids = [var.dr_database_security_group_id]

  storage_encrypted = true
  kms_key_id        = var.secondary_kms_key_arn

  backup_retention_period = var.backup_retention_period

  preferred_backup_window      = "03:00-04:00"
  preferred_maintenance_window = "sun:04:00-sun:05:00"

  skip_final_snapshot = true

  tags = merge(
    local.common_tags,
    { Name = "${var.project_name}-${var.environment}-secondary-cluster" }
  )

  depends_on = [aws_rds_cluster.primary]
}

resource "aws_rds_cluster_instance" "secondary" {
  provider = aws.dr

  count = var.secondary_instance_count

  identifier         = "${var.project_name}-${var.environment}-secondary-${count.index}"
  cluster_identifier = aws_rds_cluster.secondary.id

  instance_class = var.database_instance_class
  engine         = aws_rds_cluster.secondary.engine

  publicly_accessible        = false
  auto_minor_version_upgrade = true

  tags = merge(
    local.common_tags,
    { Name = "${var.project_name}-${var.environment}-secondary-${count.index}" }
  )
}

# RDS PROXY (ADR-05 — required for Fargate connection pooling)

resource "aws_iam_role" "rds_proxy" {
  provider = aws.primary

  name = "${var.project_name}-${var.environment}-rds-proxy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "rds.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "rds_proxy_secrets" {
  provider = aws.primary

  name = "${var.project_name}-${var.environment}-rds-proxy-secrets"
  role = aws_iam_role.rds_proxy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = [aws_rds_cluster.primary.master_user_secret[0].secret_arn]
      },
      {
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = [var.database_kms_key_arn]
      }
    ]
  })
}

resource "aws_db_proxy" "primary" {
  provider = aws.primary

  name                   = "${var.project_name}-${var.environment}-proxy"
  engine_family          = "POSTGRESQL"
  role_arn               = aws_iam_role.rds_proxy.arn
  vpc_subnet_ids         = var.private_db_subnet_ids
  vpc_security_group_ids = [var.database_security_group_id]

  require_tls = true

  auth {
    auth_scheme = "SECRETS"
    iam_auth    = "DISABLED"
    secret_arn  = aws_rds_cluster.primary.master_user_secret[0].secret_arn
  }

  tags = merge(
    local.common_tags,
    { Name = "${var.project_name}-${var.environment}-rds-proxy" }
  )
}

resource "aws_db_proxy_default_target_group" "primary" {
  provider = aws.primary

  db_proxy_name = aws_db_proxy.primary.name

  connection_pool_config {
    max_connections_percent      = 100
    max_idle_connections_percent = 50
  }
}

resource "aws_db_proxy_target" "primary" {
  provider = aws.primary

  db_proxy_name         = aws_db_proxy.primary.name
  target_group_name     = aws_db_proxy_default_target_group.primary.name
  db_cluster_identifier = aws_rds_cluster.primary.id
}
