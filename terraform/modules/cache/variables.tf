variable "project_name" {
  description = "Name of the project."
  type        = string
}

variable "environment" {
  description = "Deployment environment."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where Redis will be deployed."
  type        = string
}

variable "private_app_subnet_ids" {
  description = "Private application subnet IDs used by the Redis subnet group."
  type        = list(string)

  validation {
    condition     = length(var.private_app_subnet_ids) >= 2
    error_message = "At least two private application subnets are required."
  }
}

variable "redis_security_group_id" {
  description = "Security group ID assigned to the Redis cluster."
  type        = string
}

variable "redis_node_type" {
  description = "ElastiCache Redis node instance type."
  type        = string
  default     = "cache.t4g.micro"
}

variable "redis_engine_version" {
  description = "Redis engine version."
  type        = string
  default     = "7.1"
}

variable "redis_port" {
  description = "Redis port."
  type        = number
  default     = 6379
}

variable "redis_num_cache_nodes" {
  description = "Number of Redis cache nodes."
  type        = number
  default     = 1

  validation {
    condition     = var.redis_num_cache_nodes >= 1
    error_message = "Redis must have at least one cache node."
  }
}

variable "parameter_group_family" {
  description = "ElastiCache parameter group family."
  type        = string
  default     = "redis7"
}

variable "snapshot_retention_limit" {
  description = "Number of automatic Redis snapshots to retain."
  type        = number
  default     = 1
}

variable "snapshot_window" {
  description = "Daily snapshot window."
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Weekly Redis maintenance window."
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "transit_encryption_enabled" {
  description = "Enable encryption of Redis traffic in transit."
  type        = bool
  default     = true
}

variable "at_rest_encryption_enabled" {
  description = "Enable encryption of Redis data at rest."
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ID or ARN used to encrypt Redis at rest."
  type        = string
  default     = null
}

variable "automatic_failover_enabled" {
  description = "Enable automatic Redis failover."
  type        = bool
  default     = false
}

variable "multi_az_enabled" {
  description = "Enable Redis Multi-AZ."
  type        = bool
  default     = false
}

variable "apply_immediately" {
  description = "Apply Redis modifications immediately."
  type        = bool
  default     = false
}

variable "log_delivery_enabled" {
  description = "Whether Redis slow-log delivery should be configured."
  type        = bool
  default     = false
}

variable "common_tags" {
  description = "Common resource tags."
  type        = map(string)
  default     = {}
}
