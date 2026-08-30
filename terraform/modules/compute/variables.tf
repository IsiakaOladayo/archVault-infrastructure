variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where compute resources will be deployed"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs used by the Application Load Balancer"
  type        = list(string)
}

variable "private_app_subnet_ids" {
  description = "Private application subnet IDs used by ECS tasks"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group ID for the Application Load Balancer"
  type        = string
}

variable "application_security_group_id" {
  description = "Security group ID for ECS application tasks"
  type        = string
}

variable "container_image" {
  description = "Container image used by the ECS application"
  type        = string
  default     = "nginx:latest"
}

variable "container_port" {
  description = "Port exposed by the application container"
  type        = number
  default     = 3000
}

variable "app_port" {
  description = "Port used by the ECS application and ALB target group"
  type        = number
  default     = 3000
}

variable "desired_count" {
  description = "Number of ECS tasks to run"
  type        = number
  default     = 2
}

variable "cpu" {
  description = "Fargate task CPU units"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Fargate task memory in MiB"
  type        = number
  default     = 512
}

variable "health_check_path" {
  description = "HTTP path used by the ALB health check"
  type        = string
  default     = "/health"
}

variable "log_retention_days" {
  description = "Number of days CloudWatch logs are retained"
  type        = number
  default     = 30
}

variable "enable_execute_command" {
  description = "Enable ECS Exec for troubleshooting"
  type        = bool
  default     = true
}

variable "common_tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}
}
