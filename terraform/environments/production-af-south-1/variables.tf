variable "project_name" {
  description = "Name of the project"
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

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "availability_zones" {
  description = "Availability Zones for the production environment"
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "TradeCore requires at least two Availability Zones."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_app_subnet_cidrs" {
  description = "CIDR blocks for private application subnets"
  type        = list(string)
}

variable "private_db_subnet_cidrs" {
  description = "CIDR blocks for private database subnets"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Whether to create NAT Gateways"
  type        = bool
  default     = true
}

variable "common_tags" {
  description = "Common tags applied to resources"
  type        = map(string)
  default     = {}
}

variable "dr_region" {
  description = "Disaster recovery region"
  type        = string
}

variable "container_image" {
  description = "Container image for the ArchVault application"
  type        = string
  default     = "nginx:latest"
}

variable "container_port" {
  description = "Container port used by the application"
  type        = number
  default     = 3000
}

variable "app_port" {
  description = "Application port exposed through the ALB"
  type        = number
  default     = 3000
}

variable "ecs_desired_count" {
  description = "Number of ECS tasks to run"
  type        = number
  default     = 2
}

variable "redis_node_type" {
  description = "ElastiCache Redis node type."
  type        = string
  default     = "cache.t4g.micro"
}

variable "redis_engine_version" {
  description = "Redis engine version."
  type        = string
  default     = "7.1"
}

variable "redis_num_cache_nodes" {
  description = "Number of Redis cache nodes."
  type        = number
  default     = 1
}

variable "redis_automatic_failover_enabled" {
  description = "Enable automatic Redis failover."
  type        = bool
  default     = false
}

variable "redis_multi_az_enabled" {
  description = "Enable Redis Multi-AZ."
  type        = bool
  default     = false
}
