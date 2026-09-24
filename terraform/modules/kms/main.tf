locals {
  common_tags = merge(
    var.common_tags,
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Layer       = "Security"
    }
  )
}

data "aws_caller_identity" "primary" {
  provider = aws.primary
}

# AURORA DATABASE KEY (multi-region — primary + DR replica)

resource "aws_kms_key" "database" {
  provider = aws.primary

  description             = "CMK for Aurora PostgreSQL encryption (${var.project_name}-${var.environment})"
  multi_region            = true
  enable_key_rotation     = true
  rotation_period_in_days = 365
  deletion_window_in_days = var.deletion_window_in_days

  tags = merge(
    local.common_tags,
    { Name = "${var.project_name}-${var.environment}-database-cmk" }
  )
}

resource "aws_kms_alias" "database" {
  provider = aws.primary

  name          = "alias/${var.project_name}-${var.environment}-database"
  target_key_id = aws_kms_key.database.key_id
}

# DR replica key — Zero Knowledge Storage (ADR-02):
# only the RDS service principal may decrypt, for storage-page
# replication only. No human/IAM principal is granted kms:Decrypt.

resource "aws_kms_replica_key" "database_dr" {
  provider = aws.dr

  description             = "DR replica CMK for Aurora (eu-west-1) — Zero Knowledge Storage"
  primary_key_arn         = aws_kms_key.database.arn
  deletion_window_in_days = var.deletion_window_in_days

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowRootKeyAdministration"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.primary.account_id}:root"
        }
        Action = [
          "kms:Describe*",
          "kms:Get*",
          "kms:List*",
          "kms:TagResource",
          "kms:UntagResource",
          "kms:PutKeyPolicy",
          "kms:UpdateKeyDescription",
          "kms:EnableKey",
          "kms:DisableKey",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowRDSReplicationDecrypt"
        Effect = "Allow"
        Principal = {
          Service = var.rds_service_principal
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKeyWithoutPlaintext",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource  = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "rds.eu-west-1.amazonaws.com"
          }
        }
      },
      {
        Sid       = "DenyDecryptToAllOtherPrincipals"
        Effect    = "Deny"
        Principal = "*"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:GenerateDataKeyWithoutPlaintext"
        ]
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "aws:PrincipalServiceName" = var.rds_service_principal
          }
        }
      }
    ]
  })

  tags = merge(
    local.common_tags,
    { Name = "${var.project_name}-${var.environment}-database-cmk-dr" }
  )
}

# S3 DOCUMENTS (INVOICES) KEY

resource "aws_kms_key" "documents" {
  provider = aws.primary

  description             = "CMK for S3 invoice/document encryption (${var.project_name}-${var.environment})"
  enable_key_rotation     = true
  rotation_period_in_days = 365
  deletion_window_in_days = var.deletion_window_in_days
  multi_region            = var.enable_documents_dr_replication

  tags = merge(
    local.common_tags,
    { Name = "${var.project_name}-${var.environment}-documents-cmk" }
  )
}

resource "aws_kms_alias" "documents" {
  provider = aws.primary

  name          = "alias/${var.project_name}-${var.environment}-documents"
  target_key_id = aws_kms_key.documents.key_id
}

# Only created if cross-region document replication is explicitly
# approved — see the open data-residency ADR before enabling.

resource "aws_kms_replica_key" "documents_dr" {
  count = var.enable_documents_dr_replication ? 1 : 0

  provider = aws.dr

  description             = "DR replica CMK for S3 documents (eu-west-1)"
  primary_key_arn         = aws_kms_key.documents.arn
  deletion_window_in_days = var.deletion_window_in_days

  tags = merge(
    local.common_tags,
    { Name = "${var.project_name}-${var.environment}-documents-cmk-dr" }
  )
}

# S3 LOGS KEY (primary region only — audit logs, WAF logs, VPC Flow Logs)

resource "aws_kms_key" "logs" {
  provider = aws.primary

  description             = "CMK for S3 log storage encryption (${var.project_name}-${var.environment})"
  enable_key_rotation     = true
  rotation_period_in_days = 365
  deletion_window_in_days = var.deletion_window_in_days

  tags = merge(
    local.common_tags,
    { Name = "${var.project_name}-${var.environment}-logs-cmk" }
  )
}

resource "aws_kms_alias" "logs" {
  provider = aws.primary

  name          = "alias/${var.project_name}-${var.environment}-logs"
  target_key_id = aws_kms_key.logs.key_id
}

# SECRETS MANAGER KEY (primary region only)

resource "aws_kms_key" "secrets" {
  provider = aws.primary

  description             = "CMK for Secrets Manager credential encryption (${var.project_name}-${var.environment})"
  enable_key_rotation     = true
  rotation_period_in_days = 365
  deletion_window_in_days = var.deletion_window_in_days

  tags = merge(
    local.common_tags,
    { Name = "${var.project_name}-${var.environment}-secrets-cmk" }
  )
}

resource "aws_kms_alias" "secrets" {
  provider = aws.primary

  name          = "alias/${var.project_name}-${var.environment}-secrets"
  target_key_id = aws_kms_key.secrets.key_id
}
