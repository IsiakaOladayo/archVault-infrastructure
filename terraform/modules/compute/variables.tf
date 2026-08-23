variable "project_name" {
  description = "Name of the project."
  type        = string
}


#Environment

variable "environment" {
  description = "Deployment environment."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where compute resources will be deployed."
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs where the Application Load Balancer will be deployed."
  type        = list(string)
}

variable "application_subnet_ids" {
  description = "List of private application subnet IDs where EC2 instances will be deployed."
  type        = list(string)
}

# EC2


variable "instance_type" {
  description = "EC2 instance type for application servers."
  type        = string
  default     = "t3.micro"
}

variable "ssh_key_name" {
  description = "Name of the EC2 key pair used for SSH access. Set to null to disable SSH key configuration."
  type        = string
  default     = null
}

#Application


variable "app_port" {
  description = "Port on which the application listens."
  type        = number
  default     = 3000
}

variable "health_check_path" {
  description = "HTTP path used by the Application Load Balancer to perform health checks."
  type        = string
  default     = "/health"
}

# Auto Scaling


variable "min_size" {
  description = "Minimum number of EC2 instances in the Auto Scaling Group."
  type        = number
  default     = 2

  validation {
    condition     = var.min_size >= 1
    error_message = "min_size must be at least 1."
  }
}

variable "desired_capacity" {
  description = "Desired number of EC2 instances in the Auto Scaling Group."
  type        = number
  default     = 2

  validation {
    condition     = var.desired_capacity >= 1
    error_message = "desired_capacity must be at least 1."
  }
}

variable "max_size" {
  description = "Maximum number of EC2 instances in the Auto Scaling Group."
  type        = number
  default     = 6

  validation {
    condition     = var.max_size >= 1
    error_message = "max_size must be at least 1."
  }
}

variable "common_tags" {
  description = "Common tags applied to all compute resources."
  type        = map(string)
  default     = {}
}
