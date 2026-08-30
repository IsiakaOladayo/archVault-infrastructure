locals {
  common_tags = merge(
    var.common_tags,
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Layer       = "Compute"
    }
  )
}

# ---------------------------------------------------------
# CloudWatch Logs
# ---------------------------------------------------------

resource "aws_cloudwatch_log_group" "application" {
  name              = "/ecs/${var.project_name}/${var.environment}/application"
  retention_in_days = var.log_retention_days

  tags = merge(
    local.common_tags,
    {
      Name = "/ecs/${var.project_name}/${var.environment}/application"
    }
  )
}

# ---------------------------------------------------------
# ECS Cluster
# ---------------------------------------------------------

resource "aws_ecs_cluster" "application" {
  name = "${var.project_name}-${var.environment}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-ecs-cluster"
    }
  )
}

# ---------------------------------------------------------
# ECS Task Execution Role
# ---------------------------------------------------------

resource "aws_iam_role" "ecs_task_execution" {
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

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-ecs-execution-role"
    }
  )
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role = aws_iam_role.ecs_task_execution.name

  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ---------------------------------------------------------
# ECS Task Role
# ---------------------------------------------------------

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

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-ecs-task-role"
    }
  )
}

# ---------------------------------------------------------
# ECS Task Definition
# ---------------------------------------------------------

resource "aws_ecs_task_definition" "application" {
  family = "${var.project_name}-${var.environment}"

  network_mode = "awsvpc"

  requires_compatibilities = [
    "FARGATE"
  ]

  cpu    = var.cpu
  memory = var.memory

  execution_role_arn = aws_iam_role.ecs_task_execution.arn
  task_role_arn      = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name  = "${var.project_name}-application"
      image = var.container_image

      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          awslogs-group         = aws_cloudwatch_log_group.application.name
          awslogs-region        = "af-south-1"
          awslogs-stream-prefix = "ecs"
        }
      }

      healthCheck = {
        command = [
          "CMD-SHELL",
          "wget --no-verbose --tries=1 --spider http://localhost:${var.container_port}${var.health_check_path} || exit 1"
        ]

        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 30
      }
    }
  ])

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-task-definition"
    }
  )
}

# ---------------------------------------------------------
# Application Load Balancer
# ---------------------------------------------------------

resource "aws_lb" "application" {
  name = "${var.project_name}-${var.environment}-alb"

  internal           = false
  load_balancer_type = "application"

  security_groups = [
    var.alb_security_group_id
  ]

  subnets = var.public_subnet_ids

  enable_deletion_protection = false

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-alb"
    }
  )
}

# ---------------------------------------------------------
# ALB Target Group
# ---------------------------------------------------------

resource "aws_lb_target_group" "application" {
  name = "${var.project_name}-${var.environment}-tg"

  port     = var.app_port
  protocol = "HTTP"

  target_type = "ip"

  vpc_id = var.vpc_id

  health_check {
    enabled = true

    path     = var.health_check_path
    protocol = "HTTP"

    port = "traffic-port"

    healthy_threshold   = 2
    unhealthy_threshold = 3

    timeout  = 5
    interval = 30

    matcher = "200-399"
  }

  deregistration_delay = 30

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-target-group"
    }
  )
}

# ---------------------------------------------------------
# ALB HTTP Listener
# ---------------------------------------------------------

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.application.arn

  port     = 80
  protocol = "HTTP"

  default_action {
    type = "forward"

    target_group_arn = aws_lb_target_group.application.arn
  }

  tags = local.common_tags
}

# ---------------------------------------------------------
# ECS Service
# ---------------------------------------------------------

resource "aws_ecs_service" "application" {
  name = "${var.project_name}-${var.environment}"

  cluster = aws_ecs_cluster.application.id

  task_definition = aws_ecs_task_definition.application.arn

  desired_count = var.desired_count

  launch_type = "FARGATE"

  platform_version = "LATEST"

  enable_execute_command = var.enable_execute_command

  network_configuration {
    subnets = var.private_app_subnet_ids

    security_groups = [
      var.application_security_group_id
    ]

    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.application.arn

    container_name = "${var.project_name}-application"

    container_port = var.container_port
  }

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  health_check_grace_period_seconds = 60

  depends_on = [
    aws_lb_listener.http
  ]

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-ecs-service"
    }
  )
}
