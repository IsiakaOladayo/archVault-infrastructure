variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where security resources will be created"
  type        = string
}

variable "alb_ingress_cidr_blocks" {
  description = "CIDR blocks allowed to access the ALB"
  type        = list(string)

  default = [
    "0.0.0.0/0"
  ]
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
  description = "Whether to create the WAF Web ACL"
  type        = bool
  default     = true
}

variable "common_tags" {
  description = "Common tags applied to security resources"
  type        = map(string)
  default     = {}
}
