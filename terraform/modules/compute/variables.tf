variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnets for the ALB"
  type        = list(string)
}

variable "private_app_subnet_ids" {
  description = "Private subnets for ECS tasks"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group for the ALB"
  type        = string
}

variable "ecs_security_group_id" {
  description = "Security group for ECS tasks"
  type        = string
}

variable "container_image" {
  description = "Container image URI"
  type        = string
}

variable "container_port" {
  description = "Application container port"
  type        = number
  default     = 3000
}

variable "desired_count" {
  description = "Initial desired ECS task count"
  type        = number
  default     = 2
}

variable "min_capacity" {
  description = "Minimum ECS task count"
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Maximum ECS task count"
  type        = number
  default     = 20
}

variable "common_tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}
}
