data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    Module      = "Security"
    Compliance  = "NDPA"
    ManagedBy   = "Terraform"
  }
}

resource "aws_kms_key" "database" {
  description             = "Customer-managed KMS key for ArchVault database encryption"
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = true

  policy = data.aws_iam_policy_document.database_key.json

  tags = merge(
    local.common_tags,
    {
      Name     = "${var.project_name}-${var.environment}-kms-database"
      DataType = "FinancialData"
    }
  )
}

resource "aws_kms_alias" "database" {
  name          = "alias/${var.project_name}-${var.environment}-database"
  target_key_id = aws_kms_key.database.key_id
}

resource "aws_kms_key" "documents" {
  description             = "Customer-managed KMS key for ArchVault document encryption"
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = true

  tags = merge(
    local.common_tags,
    {
      Name     = "${var.project_name}-${var.environment}-kms-documents"
      DataType = "FinancialDocuments"
    }
  )
}

resource "aws_kms_alias" "documents" {
  name          = "alias/${var.project_name}-${var.environment}-documents"
  target_key_id = aws_kms_key.documents.key_id
}

resource "aws_kms_key" "secrets" {
  description             = "Customer-managed KMS key for ArchVault Secrets Manager secrets"
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = true

  tags = merge(
    local.common_tags,
    {
      Name     = "${var.project_name}-${var.environment}-kms-secrets"
      DataType = "Secrets"
    }
  )
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/${var.project_name}-${var.environment}-secrets"
  target_key_id = aws_kms_key.secrets.key_id
}

data "aws_iam_policy_document" "database_key" {
  statement {
    sid    = "EnableAccountAdministration"
    effect = "Allow"

    principals {
      type = "AWS"

      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }
}
