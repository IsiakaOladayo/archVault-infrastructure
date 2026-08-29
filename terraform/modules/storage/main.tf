locals {
  common_tags = merge(
    var.common_tags,
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Layer       = "Storage"
    }
  )
}

resource "aws_s3_bucket" "primary" {
  provider = aws.primary

  bucket = "${var.project_name}-${var.environment}-documents"

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-documents"
    }
  )
}

resource "aws_s3_bucket" "replica" {
  provider = aws.replica

  bucket = "${var.project_name}-${var.environment}-documents-dr"

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-documents-dr"
    }
  )
}

resource "aws_s3_bucket_versioning" "primary" {
  provider = aws.primary

  bucket = aws_s3_bucket.primary.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "replica" {
  provider = aws.replica

  bucket = aws_s3_bucket.replica.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "primary" {
  provider = aws.primary

  bucket = aws_s3_bucket.primary.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.documents_kms_key_primary_arn
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "replica" {
  provider = aws.replica

  bucket = aws_s3_bucket.replica.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.documents_kms_key_dr_arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "primary" {
  provider = aws.primary

  bucket = aws_s3_bucket.primary.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "replica" {
  provider = aws.replica

  bucket = aws_s3_bucket.replica.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "primary" {
  provider = aws.primary

  bucket = aws_s3_bucket.primary.id

  rule {
    id     = "documents-lifecycle"
    status = "Enabled"

    filter {}

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 3650
    }
  }
}

resource "aws_iam_role" "replication" {
  name = "${var.project_name}-${var.environment}-s3-replication"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "s3.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "replication" {
  name = "${var.project_name}-${var.environment}-replication-policy"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "SourceBucketAccess"
        Effect = "Allow"

        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]

        Resource = aws_s3_bucket.primary.arn
      },

      {
        Sid    = "SourceObjectAccess"
        Effect = "Allow"

        Action = [
          "s3:GetObjectVersion",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ]

        Resource = "${aws_s3_bucket.primary.arn}/*"
      },

      {
        Sid    = "DestinationObjectAccess"
        Effect = "Allow"

        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]

        Resource = "${aws_s3_bucket.replica.arn}/*"
      },

      {
        Sid    = "SourceKMSAccess"
        Effect = "Allow"

        Action = [
          "kms:Decrypt"
        ]

        Resource = var.documents_kms_key_primary_arn
      },

      {
        Sid    = "DestinationKMSAccess"
        Effect = "Allow"

        Action = [
          "kms:Encrypt",
          "kms:GenerateDataKey"
        ]

        Resource = var.documents_kms_key_dr_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "replication" {
  role       = aws_iam_role.replication.name
  policy_arn = aws_iam_policy.replication.arn
}

resource "aws_s3_bucket_replication_configuration" "primary" {
  provider = aws.primary

  depends_on = [
    aws_s3_bucket_versioning.primary,
    aws_s3_bucket_versioning.replica,
    aws_iam_role_policy_attachment.replication
  ]

  bucket = aws_s3_bucket.primary.id

  role = aws_iam_role.replication.arn

  rule {
    id     = "dr-replication"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.replica.arn
      storage_class = "STANDARD"
      
      encryption_configuration {
        replica_kms_key_id = var.documents_kms_key_dr_arn
      }
    }

    filter {}
  }
}


