# SECURITY GROUPS

output "alb_security_group_id" {
  description = "ID of the security group attached to the Application Load Balancer."
  value       = aws_security_group.alb.id
}

output "application_security_group_id" {
  description = "ID of the security group attached to the application EC2 instances."
  value       = aws_security_group.application.id
}

# APPLICATION LOAD BALANCER

output "alb_id" {
  description = "ID of the Application Load Balancer."
  value       = aws_lb.application.id
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer."
  value       = aws_lb.application.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer."
  value       = aws_lb.application.dns_name
}

output "alb_zone_id" {
  description = "Canonical hosted zone ID of the Application Load Balancer."
  value       = aws_lb.application.zone_id
}

# TARGET GROUP

output "target_group_id" {
  description = "ID of the application target group."
  value       = aws_lb_target_group.application.id
}

output "target_group_arn" {
  description = "ARN of the application target group."
  value       = aws_lb_target_group.application.arn
}

output "target_group_name" {
  description = "Name of the application target group."
  value       = aws_lb_target_group.application.name
}

# LAUNCH TEMPLATE

output "launch_template_id" {
  description = "ID of the application EC2 Launch Template."
  value       = aws_launch_template.application.id
}

output "launch_template_arn" {
  description = "ARN of the application EC2 Launch Template."
  value       = aws_launch_template.application.arn
}

# AUTO SCALING GROUP

output "autoscaling_group_id" {
  description = "ID of the application Auto Scaling Group."
  value       = aws_autoscaling_group.application.id
}

output "autoscaling_group_name" {
  description = "Name of the application Auto Scaling Group."
  value       = aws_autoscaling_group.application.name
}

# AUTO SCALING POLICY

output "autoscaling_policy_arn" {
  description = "ARN of the CPU target tracking Auto Scaling policy."
  value       = aws_autoscaling_policy.cpu_target.arn
}

# AMI

output "ubuntu_ami_id" {
  description = "Ubuntu 24.04 AMI ID retrieved from AWS Systems Manager Parameter Store."
  value       = data.aws_ssm_parameter.ubuntu_ami.value
}
