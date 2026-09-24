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

variable "flow_log_retention_days" {
  description = "Number of days VPC Flow Logs are retained in CloudWatch"
  type        = number
  default     = 90
}

variable "flow_log_kms_key_arn" {
  description = "KMS key ARN used to encrypt the VPC Flow Logs CloudWatch log group. Null uses default CloudWatch encryption."
  type        = string
  default     = null
}


variable "dr_vpc_cidr" {
  description = "CIDR block for the DR-region (eu-west-1) VPC"
  type        = string
}

variable "dr_availability_zones" {
  description = "Availability Zones used in the DR region"
  type        = list(string)

  validation {
    condition     = length(var.dr_availability_zones) >= 2
    error_message = "The DR VPC requires at least two Availability Zones (Aurora subnet groups need 2+ even for a single-instance pilot-light reader)."
  }
}

variable "dr_public_subnet_cidrs" {
  description = "CIDR blocks for DR public subnets"
  type        = list(string)

  validation {
    condition     = length(var.dr_public_subnet_cidrs) == length(var.dr_availability_zones)
    error_message = "The number of DR public subnet CIDRs must match the number of DR Availability Zones."
  }
}

variable "dr_private_app_subnet_cidrs" {
  description = "CIDR blocks for DR private application subnets (holds the pilot-light ECS health-check task per ADR-02)"
  type        = list(string)

  validation {
    condition     = length(var.dr_private_app_subnet_cidrs) == length(var.dr_availability_zones)
    error_message = "The number of DR private app subnet CIDRs must match the number of DR Availability Zones."
  }
}

variable "dr_private_db_subnet_cidrs" {
  description = "CIDR blocks for DR private database subnets (Aurora secondary cluster)"
  type        = list(string)

  validation {
    condition     = length(var.dr_private_db_subnet_cidrs) == length(var.dr_availability_zones)
    error_message = "The number of DR private db subnet CIDRs must match the number of DR Availability Zones."
  }
}

variable "enable_dr_nat_gateway" {
  description = "Whether a NAT Gateway is created in the DR region"
  type        = bool
  default     = true
}

variable "enable_dr_flow_logs" {
  description = "Whether VPC Flow Logs are enabled in the DR region"
  type        = bool
  default     = true
}

variable "dr_flow_log_kms_key_arn" {
  description = "KMS key ARN (DR-region CMK) used to encrypt the DR VPC Flow Logs log group"
  type        = string
  default     = null
}

variable "dr_flow_log_retention_days" {
  description = "Number of days DR VPC Flow Logs are retained in CloudWatch"
  type        = number
  default     = 90
}
