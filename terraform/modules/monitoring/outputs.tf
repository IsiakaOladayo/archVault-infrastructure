output "log_group_name" {
  description = "ECS application log group referenced by this module's alarms/dashboards"
  value       = var.log_group_name
}

output "alarm_arns" {
  description = "ARNs of all CloudWatch alarms created by this module"
  value = [
    aws_cloudwatch_metric_alarm.alb_5xx_rate.arn,
    aws_cloudwatch_metric_alarm.ecs_task_count_low.arn,
    aws_cloudwatch_metric_alarm.aurora_replica_lag.arn,
    aws_cloudwatch_metric_alarm.elasticache_memory.arn,
    aws_cloudwatch_metric_alarm.rds_proxy_connections.arn,
  ]
}

output "alarm_sns_topic_arn" {
  description = "ARN of the SNS topic alarms notify"
  value       = local.alarm_topic_arn
}

output "dashboard_names" {
  description = "Names of all CloudWatch dashboards created by this module"
  value = [
    aws_cloudwatch_dashboard.alb.dashboard_name,
    aws_cloudwatch_dashboard.ecs.dashboard_name,
    aws_cloudwatch_dashboard.aurora.dashboard_name,
    aws_cloudwatch_dashboard.elasticache.dashboard_name,
    aws_cloudwatch_dashboard.executive.dashboard_name,
  ]
}
