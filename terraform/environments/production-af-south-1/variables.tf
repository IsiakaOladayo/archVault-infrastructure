variable "project_name" {
  description = "Name of the ArchVault platform."
  type        = string
  default     = "archvault"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "production"

  validation {
    condition     = var.environment == "production"
    error_message = "Environment must be production."
  }
}

variable "primary_region" {
  description = "Primary AWS Region for ArchVault."
  type        = string
  default     = "af-south-1"

  validation {
    condition     = var.primary_region == "af-south-1"
    error_message = "ArchVault's primary region must be af-south-1."
  }
}

variable "compute_instance_type" {
  type        = string
  description = "EC2 instance type for the application tier."
  default     = "t3.micro"
}

variable "common_tags" {
  description = "Common tags applied to all ArchVault resources."
  type        = map(string)

  default = {
    Project   = "ArchVault"
    ManagedBy = "Terraform"
  }
}
