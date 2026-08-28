variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the ArchVault VPC"
  type        = string
}

variable "availability_zones" {
  description = "Availability Zones used by the environment"
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "ArchVault requires at least two Availability Zones."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_cidrs) == length(var.availability_zones)
    error_message = "The number of public subnet CIDRs must match the number of Availability Zones."
  }
}

variable "private_app_subnet_cidrs" {
  description = "CIDR blocks for private application subnets"
  type        = list(string)

  validation {
    condition     = length(var.private_app_subnet_cidrs) == length(var.availability_zones)
    error_message = "The number of private application subnet CIDRs must match the number of Availability Zones."
  }
}

variable "private_db_subnet_cidrs" {
  description = "CIDR blocks for private database subnets"
  type        = list(string)

  validation {
    condition     = length(var.private_db_subnet_cidrs) == length(var.availability_zones)
    error_message = "The number of private database subnet CIDRs must match the number of Availability Zones."
  }
}

variable "enable_nat_gateway" {
  description = "Whether NAT Gateways should be created"
  type        = bool
  default     = true
}

variable "common_tags" {
  description = "Common tags applied to networking resources"
  type        = map(string)
  default     = {}
}
