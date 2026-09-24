locals {
  dr_common_tags = merge(
    var.common_tags,
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Layer       = "Networking"
      Region      = "DR"
    }
  )
}

# DR VPC (eu-west-1)

resource "aws_vpc" "dr" {
  provider = aws.dr

  cidr_block           = var.dr_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.dr_common_tags, { Name = "${var.project_name}-${var.environment}-dr-vpc" })
}

resource "aws_internet_gateway" "dr" {
  provider = aws.dr
  vpc_id   = aws_vpc.dr.id

  tags = merge(local.dr_common_tags, { Name = "${var.project_name}-${var.environment}-dr-igw" })
}

# DR SUBNETS — same 3-tier pattern as primary

resource "aws_subnet" "dr_public" {
  provider = aws.dr
  count    = length(var.dr_availability_zones)

  vpc_id                  = aws_vpc.dr.id
  cidr_block               = var.dr_public_subnet_cidrs[count.index]
  availability_zone         = var.dr_availability_zones[count.index]
  map_public_ip_on_launch   = true

  tags = merge(
    local.dr_common_tags,
    {
      Name = "${var.project_name}-${var.environment}-dr-public-${var.dr_availability_zones[count.index]}"
      Tier = "Public"
    }
  )
}

resource "aws_subnet" "dr_private_app" {
  provider = aws.dr
  count    = length(var.dr_availability_zones)

  vpc_id             = aws_vpc.dr.id
  cidr_block         = var.dr_private_app_subnet_cidrs[count.index]
  availability_zone  = var.dr_availability_zones[count.index]

  tags = merge(
    local.dr_common_tags,
    {
      Name = "${var.project_name}-${var.environment}-dr-private-app-${var.dr_availability_zones[count.index]}"
      Tier = "Private-App"
    }
  )
}

resource "aws_subnet" "dr_private_db" {
  provider = aws.dr
  count    = length(var.dr_availability_zones)

  vpc_id             = aws_vpc.dr.id
  cidr_block         = var.dr_private_db_subnet_cidrs[count.index]
  availability_zone  = var.dr_availability_zones[count.index]

  tags = merge(
    local.dr_common_tags,
    {
      Name = "${var.project_name}-${var.environment}-dr-private-db-${var.dr_availability_zones[count.index]}"
      Tier = "Private-DB"
    }
  )
}

# DR NAT GATEWAY — single, regional, same pattern as primary

resource "aws_eip" "dr_nat" {
  provider = aws.dr
  count    = var.enable_dr_nat_gateway ? 1 : 0

  domain = "vpc"

  tags = merge(local.dr_common_tags, { Name = "${var.project_name}-${var.environment}-dr-nat-eip" })
}

resource "aws_nat_gateway" "dr" {
  provider = aws.dr
  count    = var.enable_dr_nat_gateway ? 1 : 0

  allocation_id = aws_eip.dr_nat[0].id
  subnet_id     = aws_subnet.dr_public[0].id

  tags = merge(local.dr_common_tags, { Name = "${var.project_name}-${var.environment}-dr-nat" })

  depends_on = [aws_internet_gateway.dr]
}

# DR ROUTE TABLES

resource "aws_route_table" "dr_public" {
  provider = aws.dr
  vpc_id   = aws_vpc.dr.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dr.id
  }

  tags = merge(local.dr_common_tags, { Name = "${var.project_name}-${var.environment}-dr-public-rt" })
}

resource "aws_route_table_association" "dr_public" {
  provider = aws.dr
  count    = length(var.dr_availability_zones)

  subnet_id      = aws_subnet.dr_public[count.index].id
  route_table_id = aws_route_table.dr_public.id
}

resource "aws_route_table" "dr_private_app" {
  provider = aws.dr
  vpc_id   = aws_vpc.dr.id

  dynamic "route" {
    for_each = var.enable_dr_nat_gateway ? [1] : []

    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.dr[0].id
    }
  }

  tags = merge(local.dr_common_tags, { Name = "${var.project_name}-${var.environment}-dr-private-app-rt" })
}

resource "aws_route_table_association" "dr_private_app" {
  provider = aws.dr
  count    = length(var.dr_availability_zones)

  subnet_id      = aws_subnet.dr_private_app[count.index].id
  route_table_id = aws_route_table.dr_private_app.id
}

# Isolated tier — no route out, same as primary
resource "aws_route_table" "dr_private_db" {
  provider = aws.dr
  vpc_id   = aws_vpc.dr.id

  tags = merge(local.dr_common_tags, { Name = "${var.project_name}-${var.environment}-dr-private-db-rt" })
}

resource "aws_route_table_association" "dr_private_db" {
  provider = aws.dr
  count    = length(var.dr_availability_zones)

  subnet_id      = aws_subnet.dr_private_db[count.index].id
  route_table_id = aws_route_table.dr_private_db.id
}

# DR VPC FLOW LOGS — same rationale as primary: enabled from day one

resource "aws_cloudwatch_log_group" "dr_flow_logs" {
  provider = aws.dr
  count    = var.enable_dr_flow_logs ? 1 : 0

  name              = "/vpc/${var.project_name}-${var.environment}/dr-flow-logs"
  retention_in_days = var.dr_flow_log_retention_days
  kms_key_id        = var.dr_flow_log_kms_key_arn

  tags = merge(local.dr_common_tags, { Name = "${var.project_name}-${var.environment}-dr-flow-logs" })
}

resource "aws_iam_role" "dr_flow_logs" {
  provider = aws.dr
  count    = var.enable_dr_flow_logs ? 1 : 0

  name = "${var.project_name}-${var.environment}-dr-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "vpc-flow-logs.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = local.dr_common_tags
}

resource "aws_iam_role_policy" "dr_flow_logs" {
  provider = aws.dr
  count    = var.enable_dr_flow_logs ? 1 : 0

  name = "${var.project_name}-${var.environment}-dr-vpc-flow-logs-policy"
  role = aws_iam_role.dr_flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "${aws_cloudwatch_log_group.dr_flow_logs[0].arn}:*"
      }
    ]
  })
}

resource "aws_flow_log" "dr" {
  provider = aws.dr
  count    = var.enable_dr_flow_logs ? 1 : 0

  log_destination_type = "cloud-watch-logs"
  log_destination        = aws_cloudwatch_log_group.dr_flow_logs[0].arn
  iam_role_arn            = aws_iam_role.dr_flow_logs[0].arn

  vpc_id       = aws_vpc.dr.id
  traffic_type = "ALL"

  max_aggregation_interval = 60

  tags = merge(local.dr_common_tags, { Name = "${var.project_name}-${var.environment}-dr-vpc-flow-log" })
}
