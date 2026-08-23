# ============================================================
# ArchVault Compute Module
# ============================================================

# ------------------------------------------------------------
# Ubuntu AMI
# ------------------------------------------------------------

data "aws_ssm_parameter" "ubuntu_ami" {
  name = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

# ------------------------------------------------------------
# Local Values
# ------------------------------------------------------------

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

# ============================================================
# SECURITY GROUPS
# ============================================================

# ------------------------------------------------------------
# ALB Security Group
# ------------------------------------------------------------

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "Security group for ArchVault Application Load Balancer"
  vpc_id      = var.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-alb-sg"
    }
  )
}

# ------------------------------------------------------------
# Application Security Group
# ------------------------------------------------------------

resource "aws_security_group" "application" {
  name        = "${var.project_name}-${var.environment}-application-sg"
  description = "Security group for ArchVault application instances"
  vpc_id      = var.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-application-sg"
    }
  )
}

# ------------------------------------------------------------
# ALB Ingress - HTTP
# ------------------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
}

# ------------------------------------------------------------
# ALB Ingress - HTTPS
# ------------------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
}

# ------------------------------------------------------------
# Application Ingress - ALB Only
# ------------------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "application_from_alb" {
  security_group_id = aws_security_group.application.id

  referenced_security_group_id = aws_security_group.alb.id

  from_port   = var.app_port
  to_port     = var.app_port
  ip_protocol = "tcp"
}

# ------------------------------------------------------------
# ALB Egress
# ------------------------------------------------------------

resource "aws_vpc_security_group_egress_rule" "alb_all" {
  security_group_id = aws_security_group.alb.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}

# ------------------------------------------------------------
# Application Egress
# ------------------------------------------------------------

resource "aws_vpc_security_group_egress_rule" "application_all" {
  security_group_id = aws_security_group.application.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}

# ============================================================
# APPLICATION LOAD BALANCER
# ============================================================

resource "aws_lb" "application" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [
    aws_security_group.alb.id
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

# ============================================================
# TARGET GROUP
# ============================================================

resource "aws_lb_target_group" "application" {
  name        = "${var.project_name}-${var.environment}-tg"
  port        = var.app_port
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    path                = var.health_check_path
    protocol            = "HTTP"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 15
    matcher             = "200-399"
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-target-group"
    }
  )
}

# ============================================================
# ALB LISTENER
# ============================================================

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.application.arn

  port     = 80
  protocol = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.application.arn
  }
}

# ============================================================
# EC2 LAUNCH TEMPLATE
# ============================================================

resource "aws_launch_template" "application" {
  name_prefix = "${var.project_name}-${var.environment}-"

  image_id      = data.aws_ssm_parameter.ubuntu_ami.value
  instance_type = var.instance_type

  key_name = var.ssh_key_name

  vpc_security_group_ids = [
    aws_security_group.application.id
  ]

  # ----------------------------------------------------------
  # Instance Metadata Service
  # ----------------------------------------------------------

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  # ----------------------------------------------------------
  # EBS Root Volume
  # ----------------------------------------------------------

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  # ----------------------------------------------------------
  # EC2 User Data
  # ----------------------------------------------------------

  user_data = base64encode(<<-EOF
    #!/bin/bash

    set -e

    apt-get update -y
    apt-get install -y nginx

    systemctl enable nginx
    systemctl start nginx

    cat > /var/www/html/index.html <<'HTML'
    <!DOCTYPE html>
    <html>
      <head>
        <title>ArchVault</title>
      </head>
      <body>
        <h1>ArchVault</h1>
        <p>Application server is running.</p>
      </body>
    </html>
    HTML

    cat > /var/www/html/health <<'HTML'
    healthy
    HTML

    # Configure nginx to listen on the application port
    cat > /etc/nginx/sites-available/default <<'NGINX'
    server {
        listen 3000 default_server;
        listen [::]:3000 default_server;

        root /var/www/html;

        index index.html;

        location / {
            try_files $uri $uri/ =404;
        }

        location /health {
            default_type text/plain;
            return 200 "healthy\n";
        }
    }
    NGINX

    nginx -t
    systemctl restart nginx
  EOF
  )

  # ----------------------------------------------------------
  # EC2 Monitoring
  # ----------------------------------------------------------

  monitoring {
    enabled = true
  }

  # ----------------------------------------------------------
  # Instance Tags
  # ----------------------------------------------------------

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      local.common_tags,
      {
        Name = "${var.project_name}-${var.environment}-application"
      }
    )
  }

  # ----------------------------------------------------------
  # EBS Volume Tags
  # ----------------------------------------------------------

  tag_specifications {
    resource_type = "volume"

    tags = merge(
      local.common_tags,
      {
        Name = "${var.project_name}-${var.environment}-application-volume"
      }
    )
  }
}

# ============================================================
# AUTO SCALING GROUP
# ============================================================

resource "aws_autoscaling_group" "application" {
  name = "${var.project_name}-${var.environment}-asg"

  min_size         = var.min_size
  desired_capacity = var.desired_capacity
  max_size         = var.max_size

  # EC2 instances are placed in private application subnets.
  vpc_zone_identifier = var.application_subnet_ids

  # Register instances automatically with the ALB target group.
  target_group_arns = [
    aws_lb_target_group.application.arn
  ]

  # Use ELB health checks rather than only EC2 status checks.
  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.application.id
    version = "$Latest"
  }

  # ----------------------------------------------------------
  # Instance Tags
  # ----------------------------------------------------------

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-application"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = local.common_tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

# ============================================================
# AUTO SCALING POLICY
# ============================================================

resource "aws_autoscaling_policy" "cpu_target" {
  name                   = "${var.project_name}-${var.environment}-cpu-target"
  autoscaling_group_name = aws_autoscaling_group.application.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 50
  }
}
