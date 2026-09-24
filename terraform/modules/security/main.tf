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

# SECURITY GROUPS — PRIMARY REGION

resource "aws_security_group" "alb" {
  provider = aws.primary

  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "Security group for the ArchVault Application Load Balancer"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, { Name = "${var.project_name}-${var.environment}-alb-sg" })
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  provider = aws.primary
  for_each = toset(var.alb_ingress_cidr_blocks)

  security_group_id = aws_security_group.alb.id
  cidr_ipv4          = each.value
  from_port          = 443
  to_port             = 443
  ip_protocol        = "tcp"
  description        = "Allow HTTPS traffic to the ALB"
}

resource "aws_vpc_security_group_ingress_rule" "alb_http_redirect" {
  provider = aws.primary
  for_each = toset(var.alb_ingress_cidr_blocks)

  security_group_id = aws_security_group.alb.id
  cidr_ipv4          = each.value
  from_port          = 80
  to_port             = 80
  ip_protocol        = "tcp"
  description        = "Allow HTTP traffic to the ALB (redirected to HTTPS)"
}

resource "aws_vpc_security_group_egress_rule" "alb_all" {
  provider = aws.primary

  security_group_id = aws_security_group.alb.id
  cidr_ipv4          = "0.0.0.0/0"
  ip_protocol        = "-1"
  description        = "Allow ALB outbound traffic"
}

resource "aws_security_group" "ecs" {
  provider = aws.primary

  name        = "${var.project_name}-${var.environment}-ecs-sg"
  description = "Security group for ArchVault ECS Fargate tasks"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, { Name = "${var.project_name}-${var.environment}-ecs-sg" })
}

resource "aws_vpc_security_group_ingress_rule" "ecs_from_alb" {
  provider = aws.primary

  security_group_id            = aws_security_group.ecs.id
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = var.ecs_container_port
  to_port                      = var.ecs_container_port
  ip_protocol                  = "tcp"
  description                  = "Allow application traffic from the ALB"
}

resource "aws_vpc_security_group_egress_rule" "ecs_all" {
  provider = aws.primary

  security_group_id = aws_security_group.ecs.id
  cidr_ipv4          = "0.0.0.0/0"
  ip_protocol        = "-1"
  description        = "Allow ECS outbound traffic"
}

resource "aws_security_group" "database" {
  provider = aws.primary

  name        = "${var.project_name}-${var.environment}-database-sg"
  description = "Security group for the primary Aurora PostgreSQL cluster"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, { Name = "${var.project_name}-${var.environment}-database-sg" })
}

resource "aws_vpc_security_group_ingress_rule" "database_from_ecs" {
  provider = aws.primary

  security_group_id            = aws_security_group.database.id
  referenced_security_group_id = aws_security_group.ecs.id
  from_port                    = var.database_port
  to_port                      = var.database_port
  ip_protocol                  = "tcp"
  description                  = "Allow PostgreSQL traffic from ECS (via RDS Proxy)"
}

resource "aws_vpc_security_group_egress_rule" "database_all" {
  provider = aws.primary

  security_group_id = aws_security_group.database.id
  cidr_ipv4          = "0.0.0.0/0"
  ip_protocol        = "-1"
  description        = "Allow database outbound traffic"
}

resource "aws_security_group" "redis" {
  provider = aws.primary

  name        = "${var.project_name}-${var.environment}-redis-sg"
  description = "Security group for ArchVault Redis"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, { Name = "${var.project_name}-${var.environment}-redis-sg" })
}

resource "aws_vpc_security_group_ingress_rule" "redis_from_ecs" {
  provider = aws.primary

  security_group_id            = aws_security_group.redis.id
  referenced_security_group_id = aws_security_group.ecs.id
  from_port                    = var.redis_port
  to_port                      = var.redis_port
  ip_protocol                  = "tcp"
  description                  = "Allow Redis traffic from ECS"
}

resource "aws_vpc_security_group_egress_rule" "redis_all" {
  provider = aws.primary

  security_group_id = aws_security_group.redis.id
  cidr_ipv4          = "0.0.0.0/0"
  ip_protocol        = "-1"
  description        = "Allow Redis outbound traffic"
}

# SECURITY GROUP — DR REGION (Aurora secondary cluster)

resource "aws_security_group" "database_dr" {
  provider = aws.dr

  name        = "${var.project_name}-${var.environment}-database-dr-sg"
  description = "Security group for the DR Aurora PostgreSQL cluster (eu-west-1)"
  vpc_id      = var.dr_vpc_id

  tags = merge(local.common_tags, { Name = "${var.project_name}-${var.environment}-database-dr-sg" })
}

# Ingress intentionally left minimal: the DR pilot-light cluster
# replicates via Aurora Global Database's internal replication path,
# not via application-layer connections, until failover is declared.
resource "aws_vpc_security_group_egress_rule" "database_dr_all" {
  provider = aws.dr

  security_group_id = aws_security_group.database_dr.id
  cidr_ipv4          = "0.0.0.0/0"
  ip_protocol        = "-1"
  description        = "Allow DR database outbound traffic"
}

# IAM — ECS EXECUTION + TASK ROLES
# (moved here from compute — see note in review)

resource "aws_iam_role" "ecs_execution" {
  provider = aws.primary

  name = "${var.project_name}-${var.environment}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  provider = aws.primary

  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task" {
  provider = aws.primary

  name = "${var.project_name}-${var.environment}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_policy" "ecs_task" {
  provider = aws.primary

  name        = "${var.project_name}-${var.environment}-ecs-task-policy"
  description = "Least-privilege permissions for the ArchVault ECS application"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DecryptApplicationSecrets"
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = var.secrets_kms_key_arn
      },
      {
        Sid      = "DecryptFinancialDocuments"
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = var.documents_kms_key_arn
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ecs_task" {
  provider = aws.primary

  role       = aws_iam_role.ecs_task.name
  policy_arn = aws_iam_policy.ecs_task.arn
}

# =========================================================
# WAF — REGIONAL (attached to the ALB)
# =========================================================

resource "aws_wafv2_web_acl" "regional" {
  count = var.enable_waf ? 1 : 0

  provider = aws.primary

  name        = "${var.project_name}-${var.environment}-waf-regional"
  scope       = "REGIONAL"
  description = "Regional WAF protection for the ArchVault ALB"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-${var.environment}-waf-regional"
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
    name     = "AWSManagedSQLiRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-${var.environment}-sqli-rules"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedKnownBadInputsRuleSet"
    priority = 3

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
    priority = 4

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

  rule {
    name     = "RateLimitPerIP"
    priority = 5

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.waf_rate_limit
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-${var.environment}-rate-limit"
      sampled_requests_enabled   = true
    }
  }

  tags = merge(local.common_tags, { Name = "${var.project_name}-${var.environment}-waf-regional" })
}

# =========================================================
# WAF — CLOUDFRONT SCOPE (must be created in us-east-1)
# =========================================================

resource "aws_wafv2_web_acl" "cloudfront" {
  count = var.enable_waf ? 1 : 0

  provider = aws.us_east_1

  name        = "${var.project_name}-${var.environment}-waf-cloudfront"
  scope       = "CLOUDFRONT"
  description = "CloudFront-scoped WAF protection for static assets and invoice downloads"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-${var.environment}-waf-cloudfront"
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
      metric_name                = "${var.project_name}-${var.environment}-cf-common-rules"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedAmazonIpReputationList"
    priority = 2

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
      metric_name                = "${var.project_name}-${var.environment}-cf-ip-reputation"
      sampled_requests_enabled   = true
    }
  }

  tags = merge(local.common_tags, { Name = "${var.project_name}-${var.environment}-waf-cloudfront" })
}
