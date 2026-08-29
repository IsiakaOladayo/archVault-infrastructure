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
  description = "Disaster recovery region"
  type        = string
}

variable "documents_kms_key_primary_arn" {
  description = "Primary-region KMS key used for document encryption"
  type        = string
}

variable "documents_kms_key_dr_arn" {
  description = "DR-region KMS key used for document encryption"
  type        = string
}

variable "common_tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}
}
