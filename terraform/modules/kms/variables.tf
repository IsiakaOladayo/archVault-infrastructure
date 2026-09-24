variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "deletion_window_in_days" {
  description = "Waiting period before a scheduled key deletion is finalized"
  type        = number
  default     = 30

  validation {
    condition     = var.deletion_window_in_days >= 7 && var.deletion_window_in_days <= 30
    error_message = "KMS deletion window must be between 7 and 30 days."
  }
}

variable "enable_documents_dr_replication" {
  description = "Whether the S3 documents (invoices) CMK is replicated to the DR region. Gated pending resolution of the data-residency ADR — leave false unless S3 CRR to eu-west-1 has been formally approved."
  type        = bool
  default     = True
}

variable "rds_service_principal" {
  description = "AWS service principal permitted to use the Aurora DR replica key for storage-page decryption during replication"
  type        = string
  default     = "rds.amazonaws.com"
}

variable "common_tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}
}
