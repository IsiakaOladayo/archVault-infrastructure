output "log_group_names" {
  description = "CloudWatch log groups created by the module"
  value       = aws_cloudwatch_log_group.application.name
}

output "alarm_arns" {
  description = "CloudWatch alarm ARNs"
  value       = aws_cloudwatch_metric_alarm.application[*].arn
}
