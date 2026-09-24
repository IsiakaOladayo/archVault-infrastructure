variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "primary_region" {
  description = "Primary AWS region"
  type        = string
}

variable "replica_region" {
  description = "DR region (only used if enable_dr_replication is true)"
  type        = string
  default     = null
}

# Gate must be kept in sync with the kms module's
# enable_documents_dr_replication variable — both default false
variable "enable_dr_replication" {
  description = "Whether invoice documents replicate to the DR region. Leave false until the data-residency ADR is resolved — the Architecture Review's documented position is no cross-region S3 replication."
  type        = bool
  default     = true
}

variable "documents_kms_key_primary_arn" {
  description = "Primary-region KMS key for invoice/document encryption"
  type        = string
}

variable "documents_kms_key_dr_arn" {
  description = "DR-region KMS key for invoice/document encryption. Required only if enable_dr_replication is true."
  type        = string
  default     = null
}

variable "logs_kms_key_arn" {
  description = "KMS key for the audit/access logs bucket"
  type        = string
}

variable "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution granted OAC access to the static and downloads buckets. Null until the cdn module exists — bucket policies stay private-only until this is supplied."
  type        = string
  default     = null
}

variable "object_lock_retention_days" {
  description = "Object Lock compliance-mode retention for the logs bucket (brief: 7-year retention)"
  type        = number
  default     = 2555
}

variable "intelligent_tiering_min_object_size" {
  description = "Objects at or above this size (bytes) transition to Intelligent-Tiering; smaller objects stay in Standard, per the cost model's stated strategy"
  type        = number
  default     = 131072 # 128 KB
}

variable "common_tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}
}
