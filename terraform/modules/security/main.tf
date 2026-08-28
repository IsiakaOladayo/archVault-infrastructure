locals {
  common_tags = merge(
    var.common_tags,
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Layer       = "Security"
    }
  )
}

#create ALB security group
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "Security group for the ArchVault Application Load Balancer"
  vpc_id      = var.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-alb-sg"
    }
  )
}

#create ALB http ingress
resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  for_each = toset(var.alb_ingress_cidr_blocks)

  security_group_id = aws_security_group.alb.id

  cidr_ipv4   = each.value
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"

  description = "Allow HTTP traffic to the ALB"
}

#create alb https ingree
resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  for_each = toset(var.alb_ingress_cidr_blocks)

  security_group_id = aws_security_group.alb.id

  cidr_ipv4   = each.value
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"

  description = "Allow HTTPS traffic to the ALB"
}

#create ALB egress
resource "aws_vpc_security_group_egress_rule" "alb_all" {
  security_group_id = aws_security_group.alb.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"

  description = "Allow ALB outbound traffic"
}

#create ECS security group
resource "aws_security_group" "ecs" {
  name        = "${var.project_name}-${var.environment}-ecs-sg"
  description = "Security group for ArchVault ECS Fargate tasks"
  vpc_id      = var.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-ecs-sg"
    }
  )
}

#ALB SG to ECS SG
resource "aws_vpc_security_group_ingress_rule" "ecs_from_alb" {
  security_group_id = aws_security_group.ecs.id

  referenced_security_group_id = aws_security_group.alb.id

  from_port   = var.ecs_container_port
  to_port     = var.ecs_container_port
  ip_protocol = "tcp"

  description = "Allow application traffic from the ALB"
}

#create ECS egress
resource "aws_vpc_security_group_egress_rule" "ecs_all" {
  security_group_id = aws_security_group.ecs.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"

  description = "Allow ECS outbound traffic"
}

#create database SG
resource "aws_security_group" "database" {
  name        = "${var.project_name}-${var.environment}-database-sg"
  description = "Security group for ArchVault Aurora PostgreSQL"
  vpc_id      = var.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-database-sg"
    }
  )
}

#connect ECS to aurora
resource "aws_vpc_security_group_ingress_rule" "database_from_ecs" {
  security_group_id = aws_security_group.database.id

  referenced_security_group_id = aws_security_group.ecs.id

  from_port   = var.database_port
  to_port     = var.database_port
  ip_protocol = "tcp"

  description = "Allow PostgreSQL traffic from ECS"
}

#create database egress
resource "aws_vpc_security_group_egress_rule" "database_all" {
  security_group_id = aws_security_group.database.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"

  description = "Allow database outbound traffic"
}

#Create redis SG
resource "aws_security_group" "redis" {
  name        = "${var.project_name}-${var.environment}-redis-sg"
  description = "Security group for ArchVault Redis"
  vpc_id      = var.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-redis-sg"
    }
  )
}

#Connect ECS to Redis
resource "aws_vpc_security_group_ingress_rule" "redis_from_ecs" {
  security_group_id = aws_security_group.redis.id

  referenced_security_group_id = aws_security_group.ecs.id

  from_port   = var.redis_port
  to_port     = var.redis_port
  ip_protocol = "tcp"

  description = "Allow Redis traffic from ECS"
}

#create Redis Egress
resource "aws_vpc_security_group_egress_rule" "redis_all" {
  security_group_id = aws_security_group.redis.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"

  description = "Allow Redis outbound traffic"
}

#create database kms key
resource "aws_kms_key" "database" {
  description = "Customer-managed KMS key for ArchVault database encryption"

  enable_key_rotation = true

  deletion_window_in_days = 30

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-database-kms"
      Data = "Financial"
    }
  )
}

#create alias
resource "aws_kms_alias" "database" {
  name = "alias/${var.project_name}-${var.environment}-database"

  target_key_id = aws_kms_key.database.key_id
}

#create KMS documnets/financial data
resource "aws_kms_key" "documents" {
  description = "Customer-managed KMS key for ArchVault financial documents"

  enable_key_rotation = true

  deletion_window_in_days = 30

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-documents-kms"
      Data = "Financial"
    }
  )
}

#create alias
resource "aws_kms_alias" "documents" {
  name = "alias/${var.project_name}-${var.environment}-documents"

  target_key_id = aws_kms_key.documents.key_id
}

#create KMS secret
resource "aws_kms_key" "secrets" {
  description = "Customer-managed KMS key for ArchVault secrets"

  enable_key_rotation = true

  deletion_window_in_days = 30

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-secrets-kms"
      Data = "Secrets"
    }
  )
}

#create aws kms alias
resource "aws_kms_alias" "secrets" {
  name = "alias/${var.project_name}-${var.environment}-secrets"

  target_key_id = aws_kms_key.secrets.key_id
}

#create ECS task execution role
resource "aws_iam_role" "ecs_execution" {
  name = "${var.project_name}-${var.environment}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

#attach aws managed execution policy
resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role = aws_iam_role.ecs_execution.name

  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

#Create ECS task role
resource "aws_iam_role" "ecs_task" {
  name = "${var.project_name}-${var.environment}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

#create ECS task policy
resource "aws_iam_policy" "ecs_task" {
  name        = "${var.project_name}-${var.environment}-ecs-task-policy"
  description = "Least-privilege permissions for the ArchVault ECS application"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "DecryptApplicationSecrets"
        Effect = "Allow"

        Action = [
          "kms:Decrypt"
        ]

        Resource = aws_kms_key.secrets.arn
      },

      {
        Sid    = "DecryptFinancialDocuments"
        Effect = "Allow"

        Action = [
          "kms:Decrypt"
        ]

        Resource = aws_kms_key.documents.arn
      }
    ]
  })

  tags = local.common_tags
}

#attach iam role policy
resource "aws_iam_role_policy_attachment" "ecs_task" {
  role = aws_iam_role.ecs_task.name

  policy_arn = aws_iam_policy.ecs_task.arn
}

#create WAF
resource "aws_wafv2_web_acl" "application" {
  count = var.enable_waf ? 1 : 0

  name  = "${var.project_name}-${var.environment}-waf"
  scope = "REGIONAL"

  description = "AWS WAF protection for ArchVault"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-${var.environment}-waf"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "AWSManagedCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-${var.environment}-common-rules"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-${var.environment}-known-bad-inputs"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedAmazonIpReputationList"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-${var.environment}-ip-reputation"
      sampled_requests_enabled   = true
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-waf"
    }
  )
} 
