variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "vpc_id" {
  description = "Primary-region VPC ID"
  type        = string
}

variable "dr_vpc_id" {
  description = "DR-region (eu-west-1) VPC ID"
  type        = string
}

variable "alb_ingress_cidr_blocks" {
  description = "CIDR blocks allowed to access the ALB"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "ecs_container_port" {
  description = "Port exposed by the ECS application"
  type        = number
  default     = 3000
}

variable "database_port" {
  description = "Aurora PostgreSQL port"
  type        = number
  default     = 5432
}

variable "redis_port" {
  description = "Redis port"
  type        = number
  default     = 6379
}

variable "enable_waf" {
  description = "Whether to create WAF Web ACLs"
  type        = bool
  default     = true
}

variable "waf_rate_limit" {
  description = "Max requests per 5-minute rolling window, per IP, before WAF blocks (ADR-08: 2,000)"
  type        = number
  default     = 2000
}

variable "documents_kms_key_arn" {
  description = "ARN of the S3 documents/invoices CMK (from the kms module), granted to the ECS task role"
  type        = string
}

variable "secrets_kms_key_arn" {
  description = "ARN of the Secrets Manager CMK (from the kms module), granted to the ECS task role"
  type        = string
}

variable "common_tags" {
  description = "Common tags applied to security resources"
  type        = map(string)
  default     = {}
}
