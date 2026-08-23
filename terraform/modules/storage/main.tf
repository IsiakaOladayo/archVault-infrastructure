# modules/storage/main.tf

resource "aws_s3_bucket" "primary_documents" {
  provider = aws.primary # af-south-1
  bucket   = "archvault-tradecore-documents-primary"
}

resource "aws_s3_bucket_versioning" "primary_versioning" {
  bucket = aws_s3_bucket.primary_documents.id
  versioning_configuration {
    status     = "Enabled"
    mfa_delete = "Enabled" # Requires root MFA token to delete versions
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "primary_encryption" {
  bucket = aws_s3_bucket.primary_documents.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.s3_kms_key_arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_policy" "strict_compliance_policy" {
  bucket = aws_s3_bucket.primary_documents.id
  policy = data.aws_iam_policy_document.s3_boundary_policy.json
}

data "aws_iam_policy_document" "s3_boundary_policy" {
  statement {
    sid       = "EnforceSSLOnly"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [
      aws_s3_bucket.primary_documents.arn,
      "${aws_s3_bucket.primary_documents.arn}/*"
    ]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid       = "DenyUnencryptedObjectUploads"
    effect    = "Deny"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.primary_documents.arn}/*"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["aws:kms"]
    }
  }
}
