variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "alb_dns_name" {
  description = "ALB DNS name used as CloudFront origin"
  type        = string
}

variable "domain_name" {
  description = "Public application domain"
  type        = string
}

variable "certificate_arn" {
  description = "ACM certificate ARN for CloudFront"
  type        = string
}

variable "waf_web_acl_arn" {
  description = "WAF Web ACL ARN"
  type        = string
}

variable "common_tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}
}
