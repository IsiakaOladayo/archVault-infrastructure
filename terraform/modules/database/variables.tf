variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_db_subnet_ids" {
  description = "Private database subnet IDs"
  type        = list(string)
}

variable "database_security_group_id" {
  description = "Security group for Aurora"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN used for database encryption"
  type        = string
}

variable "database_name" {
  description = "Initial database name"
  type        = string
}

variable "master_username" {
  description = "Aurora master username"
  type        = string
}

variable "common_tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}
}
