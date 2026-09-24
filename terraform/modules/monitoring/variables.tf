variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "ecs_cluster_name" {
  description = "ECS cluster name"
  type        = string
}

variable "ecs_service_name" {
  description = "ECS service name"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ALB ARN suffix used by CloudWatch metrics"
  type        = string
}

variable "database_cluster_id" {
  description = "Aurora cluster identifier"
  type        = string
}

variable "log_group_name" {
  description = "Name of the existing ECS application log group (created by the compute module)"
  type        = string
}

variable "ecs_min_task_count" {
  description = "Minimum healthy ECS task count before alarming"
  type        = number
  default     = 3
}

variable "elasticache_replication_group_id" {
  description = "ElastiCache Redis replication group ID"
  type        = string
}

variable "rds_proxy_name" {
  description = "Name of the RDS Proxy in front of the primary Aurora cluster"
  type        = string
}

variable "rds_proxy_max_connections" {
  description = "Maximum connections configured on the RDS Proxy target group, used to compute the 80% alarm threshold"
  type        = number
}

variable "rds_proxy_max_connections_percent" {
  description = "Threshold percentage of max proxy connections before alarming"
  type        = number
  default     = 80
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN to notify on alarm state changes. If null, a topic is created."
  type        = string
  default     = null
}

variable "alarm_email" {
  description = "Email address subscribed to the alarm SNS topic, if one is created"
  type        = string
  default     = null
}

variable "aws_region" {
  description = "AWS region dashboards render metrics from"
  type        = string
  default     = "af-south-1"
}

variable "common_tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}
}
