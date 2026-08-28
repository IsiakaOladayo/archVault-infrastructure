locals {
  common_tags = merge(
    var.common_tags,
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Layer       = "Networking"
    }
  )
}

#create vpc
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-vpc"
    }
  )
}

#internet gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-igw"
    }
  )
}

#create public subnet
resource "aws_subnet" "public" {
  count = length(var.availability_zones)

  vpc_id = aws_vpc.main.id

  cidr_block = var.public_subnet_cidrs[count.index]

  availability_zone = var.availability_zones[count.index]

  map_public_ip_on_launch = true

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-public-${var.availability_zones[count.index]}"
      Tier = "Public"
    }
  )
}

#create private app subnet
resource "aws_subnet" "private_app" {
  count = length(var.availability_zones)

  vpc_id = aws_vpc.main.id

  cidr_block = var.private_app_subnet_cidrs[count.index]

  availability_zone = var.availability_zones[count.index]

  map_public_ip_on_launch = false

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-private-app-${var.availability_zones[count.index]}"
      Tier = "Private-App"
    }
  )
}

#create private db subnet
resource "aws_subnet" "private_db" {
  count = length(var.availability_zones)

  vpc_id = aws_vpc.main.id

  cidr_block = var.private_db_subnet_cidrs[count.index]

  availability_zone = var.availability_zones[count.index]

  map_public_ip_on_launch = false

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-private-db-${var.availability_zones[count.index]}"
      Tier = "Private-DB"
    }
  )
}

#create elastic ip
resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? length(var.availability_zones) : 0

  domain = "vpc"

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-nat-eip-${count.index + 1}"
    }
  )
}

#create nat gateways
resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? length(var.availability_zones) : 0

  allocation_id = aws_eip.nat[count.index].id

  subnet_id = aws_subnet.public[count.index].id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-nat-${var.availability_zones[count.index]}"
    }
  )

  depends_on = [
    aws_internet_gateway.main
  ]
}

#create public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-public-rt"
    }
  )
}

#public route table association
resource "aws_route_table_association" "public" {
  count = length(var.availability_zones)

  subnet_id = aws_subnet.public[count.index].id

  route_table_id = aws_route_table.public.id
}

#create private app route table
resource "aws_route_table" "private_app" {
  count = length(var.availability_zones)

  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []

    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[count.index].id
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-private-app-rt-${var.availability_zones[count.index]}"
    }
  )
}


#app route table association
resource "aws_route_table_association" "private_app" {
  count = length(var.availability_zones)

  subnet_id = aws_subnet.private_app[count.index].id

  route_table_id = aws_route_table.private_app[count.index].id
}

#create db route tables
resource "aws_route_table" "private_db" {
  count = length(var.availability_zones)

  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-private-db-rt-${var.availability_zones[count.index]}"
    }
  )
}

#db route table association
resource "aws_route_table_association" "private_db" {
  count = length(var.availability_zones)

  subnet_id = aws_subnet.private_db[count.index].id

  route_table_id = aws_route_table.private_db[count.index].id
}
