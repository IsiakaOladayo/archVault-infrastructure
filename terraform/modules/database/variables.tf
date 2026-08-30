variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the database will be deployed"
  type        = string
}

variable "private_db_subnet_ids" {
  description = "Private database subnet IDs"
  type        = list(string)
}

variable "database_security_group_id" {
  description = "Security group ID for the database"
  type        = string
}

variable "database_kms_key_arn" {
  description = "KMS key ARN used to encrypt the database"
  type        = string
}

variable "database_name" {
  description = "Initial PostgreSQL database name"
  type        = string
  default     = "archvault"
}

variable "database_username" {
  description = "Master username for PostgreSQL"
  type        = string
  default     = "archvault_admin"
}

variable "database_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.micro"
}

variable "database_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "16"
}

variable "database_port" {
  description = "PostgreSQL port"
  type        = number
  default     = 5432
}

variable "allocated_storage" {
  description = "Initial allocated storage in GB"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum storage size for autoscaling in GB"
  type        = number
  default     = 100
}

variable "backup_retention_period" {
  description = "Number of days automated backups are retained"
  type        = number
  default     = 7
}

variable "common_tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}
}

variable "dr_private_db_subnet_ids" {
  description = "Private database subnet IDs in the DR region"
  type        = list(string)
}

variable "dr_database_security_group_id" {
  description = "Database security group ID in the DR region"
  type        = string
}

variable "secondary_kms_key_arn" {
  description = "KMS key ARN used to encrypt the secondary Aurora cluster"
  type        = string
}

variable "primary_instance_count" {
  description = "Number of Aurora instances in the primary cluster"
  type        = number
  default     = 2
}

variable "secondary_instance_count" {
  description = "Number of Aurora instances in the secondary cluster"
  type        = number
  default     = 1
}
