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

# DOWNLOADS BUCKET — invoice PDFs (ADR-07: downloads.tradecoreafrica.com)

resource "aws_s3_bucket" "downloads" {
  provider = aws.primary
  bucket   = "${var.project_name}-${var.environment}-downloads"

  tags = merge(local.common_tags, { Name = "${var.project_name}-${var.environment}-downloads" })
}

resource "aws_s3_bucket_versioning" "downloads" {
  provider = aws.primary
  bucket   = aws_s3_bucket.downloads.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "downloads" {
  provider = aws.primary
  bucket   = aws_s3_bucket.downloads.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.documents_kms_key_primary_arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "downloads" {
  provider = aws.primary
  bucket   = aws_s3_bucket.downloads.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "downloads" {
  provider = aws.primary
  bucket   = aws_s3_bucket.downloads.id

  rule {
    id     = "intelligent-tiering-large-objects"
    status = "Enabled"

    filter {
      object_size_greater_than = var.intelligent_tiering_min_object_size
    }

    transition {
      days          = 0
      storage_class = "INTELLIGENT_TIERING"
    }
  }
}

resource "aws_s3_bucket_policy" "downloads" {
  provider = aws.primary
  bucket   = aws_s3_bucket.downloads.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Sid       = "DenyInsecureTransport"
          Effect    = "Deny"
          Principal = "*"
          Action    = "s3:*"
          Resource = [
            aws_s3_bucket.downloads.arn,
            "${aws_s3_bucket.downloads.arn}/*"
          ]
          Condition = {
            Bool = { "aws:SecureTransport" = "false" }
          }
        }
      ],
      var.cloudfront_distribution_arn != null ? [
        {
          Sid       = "AllowCloudFrontOAC"
          Effect    = "Allow"
          Principal = { Service = "cloudfront.amazonaws.com" }
          Action    = "s3:GetObject"
          Resource  = "${aws_s3_bucket.downloads.arn}/*"
          Condition = {
            StringEquals = { "AWS:SourceArn" = var.cloudfront_distribution_arn }
          }
        }
      ] : []
    )
  })
}

# STATIC ASSETS BUCKET — web UI bundle (ADR-07: static.tradecoreafrica.com)

resource "aws_s3_bucket" "static" {
  provider = aws.primary
  bucket   = "${var.project_name}-${var.environment}-static"

  tags = merge(local.common_tags, { Name = "${var.project_name}-${var.environment}-static" })
}

resource "aws_s3_bucket_versioning" "static" {
  provider = aws.primary
  bucket   = aws_s3_bucket.static.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "static" {
  provider = aws.primary
  bucket   = aws_s3_bucket.static.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "static" {
  provider = aws.primary
  bucket   = aws_s3_bucket.static.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "static" {
  provider = aws.primary
  bucket   = aws_s3_bucket.static.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Sid       = "DenyInsecureTransport"
          Effect    = "Deny"
          Principal = "*"
          Action    = "s3:*"
          Resource = [
            aws_s3_bucket.static.arn,
            "${aws_s3_bucket.static.arn}/*"
          ]
          Condition = {
            Bool = { "aws:SecureTransport" = "false" }
          }
        }
      ],
      var.cloudfront_distribution_arn != null ? [
        {
          Sid       = "AllowCloudFrontOAC"
          Effect    = "Allow"
          Principal = { Service = "cloudfront.amazonaws.com" }
          Action    = "s3:GetObject"
          Resource  = "${aws_s3_bucket.static.arn}/*"
          Condition = {
            StringEquals = { "AWS:SourceArn" = var.cloudfront_distribution_arn }
          }
        }
      ] : []
    )
  })
}

# =========================================================
# LOGS BUCKET — audit trail (CloudTrail, WAF via Firehose)
# Object Lock (compliance mode) satisfies the brief's immutable
# 7-year audit-trail requirement. Versioning is mandatory for
# Object Lock and must be enabled at bucket creation.
# =========================================================

resource "aws_s3_bucket" "logs" {
  provider = aws.primary
  bucket   = "${var.project_name}-${var.environment}-logs"

  object_lock_enabled = true

  tags = merge(local.common_tags, { Name = "${var.project_name}-${var.environment}-logs" })
}

resource "aws_s3_bucket_versioning" "logs" {
  provider = aws.primary
  bucket   = aws_s3_bucket.logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_object_lock_configuration" "logs" {
  provider = aws.primary
  bucket   = aws_s3_bucket.logs.id

  rule {
    default_retention {
      mode = "COMPLIANCE"
      days = var.object_lock_retention_days
    }
  }

  depends_on = [aws_s3_bucket_versioning.logs]
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  provider = aws.primary
  bucket   = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.logs_kms_key_arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  provider = aws.primary
  bucket   = aws_s3_bucket.logs.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "logs" {
  provider = aws.primary
  bucket   = aws_s3_bucket.logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.logs.arn,
          "${aws_s3_bucket.logs.arn}/*"
        ]
        Condition = {
          Bool = { "aws:SecureTransport" = "false" }
        }
      },
      {
        Sid       = "AllowCloudTrailWrite"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.logs.arn}/cloudtrail/*"
        Condition = {
          StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" }
        }
      },
      {
        Sid       = "AllowCloudTrailBucketAcl"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.logs.arn
      },
      {
        Sid       = "AllowFirehoseWrite"
        Effect    = "Allow"
        Principal = { Service = "firehose.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.logs.arn}/waf/*"
      }
    ]
  })
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  provider = aws.primary
  bucket   = aws_s3_bucket.logs.id

  rule {
    id     = "logs-archival"
    status = "Enabled"

    filter {}

    transition {
      days          = 365
      storage_class = "GLACIER"
    }
  }

  depends_on = [aws_s3_bucket_object_lock_configuration.logs]
}

# DR REPLICATION — opt-in only, gated identically to the kms

resource "aws_s3_bucket" "downloads_dr" {
  count    = var.enable_dr_replication ? 1 : 0
  provider = aws.replica
  bucket   = "${var.project_name}-${var.environment}-downloads-dr"

  tags = merge(local.common_tags, { Name = "${var.project_name}-${var.environment}-downloads-dr" })
}

resource "aws_s3_bucket_versioning" "downloads_dr" {
  count    = var.enable_dr_replication ? 1 : 0
  provider = aws.replica
  bucket   = aws_s3_bucket.downloads_dr[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "downloads_dr" {
  count    = var.enable_dr_replication ? 1 : 0
  provider = aws.replica
  bucket   = aws_s3_bucket.downloads_dr[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.documents_kms_key_dr_arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "downloads_dr" {
  count    = var.enable_dr_replication ? 1 : 0
  provider = aws.replica
  bucket   = aws_s3_bucket.downloads_dr[0].id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_iam_role" "replication" {
  count    = var.enable_dr_replication ? 1 : 0
  provider = aws.primary
  name     = "${var.project_name}-${var.environment}-s3-replication"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "s3.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_policy" "replication" {
  count    = var.enable_dr_replication ? 1 : 0
  provider = aws.primary
  name     = "${var.project_name}-${var.environment}-replication-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "SourceBucketAccess"
        Effect   = "Allow"
        Action   = ["s3:GetReplicationConfiguration", "s3:ListBucket"]
        Resource = aws_s3_bucket.downloads.arn
      },
      {
        Sid      = "SourceObjectAccess"
        Effect   = "Allow"
        Action   = ["s3:GetObjectVersion", "s3:GetObjectVersionAcl", "s3:GetObjectVersionTagging"]
        Resource = "${aws_s3_bucket.downloads.arn}/*"
      },
      {
        Sid      = "DestinationObjectAccess"
        Effect   = "Allow"
        Action   = ["s3:ReplicateObject", "s3:ReplicateDelete", "s3:ReplicateTags"]
        Resource = "${aws_s3_bucket.downloads_dr[0].arn}/*"
      },
      {
        Sid      = "SourceKMSAccess"
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = var.documents_kms_key_primary_arn
      },
      {
        Sid      = "DestinationKMSAccess"
        Effect   = "Allow"
        Action   = ["kms:Encrypt", "kms:GenerateDataKey"]
        Resource = var.documents_kms_key_dr_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "replication" {
  count      = var.enable_dr_replication ? 1 : 0
  provider   = aws.primary
  role       = aws_iam_role.replication[0].name
  policy_arn = aws_iam_policy.replication[0].arn
}

resource "aws_s3_bucket_replication_configuration" "downloads" {
  count    = var.enable_dr_replication ? 1 : 0
  provider = aws.primary

  depends_on = [
    aws_s3_bucket_versioning.downloads,
    aws_s3_bucket_versioning.downloads_dr,
    aws_iam_role_policy_attachment.replication
  ]

  bucket = aws_s3_bucket.downloads.id
  role   = aws_iam_role.replication[0].arn

  rule {
    id     = "dr-replication"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.downloads_dr[0].arn
      storage_class = "STANDARD"

      encryption_configuration {
        replica_kms_key_id = var.documents_kms_key_dr_arn
      }
    }

    filter {}
  }
}
