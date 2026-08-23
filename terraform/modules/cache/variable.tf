# modules/cache/variables.tf

variable "vpc_id" {
  type        = string
  description = "VPC ID where Redis security group is created"
}

variable "isolated_subnet_ids" {
  type        = list(string)
  description = "List of Tier 3 isolated subnet IDs across 3 AZs"
}

variable "ecs_security_group_id" {
  type        = string
  description = "Security Group ID of the Tier 2 ECS Fargate tasks"
}

variable "kms_key_arn" {
  type        = string
  description = "ARN of the AWS KMS Customer-Managed Key for Redis encryption"
}
