locals {
  common_tags = merge(
    var.common_tags,
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Layer       = "Monitoring"
    }
  )
}

# SNS TOPIC FOR ALARM NOTIFICATIONS

resource "aws_sns_topic" "alarms" {
  count = var.alarm_sns_topic_arn == null ? 1 : 0

  name = "${var.project_name}-${var.environment}-alarms"

  tags = merge(
    local.common_tags,
    { Name = "${var.project_name}-${var.environment}-alarms" }
  )
}

resource "aws_sns_topic_subscription" "alarm_email" {
  count = var.alarm_sns_topic_arn == null && var.alarm_email != null ? 1 : 0

  topic_arn = aws_sns_topic.alarms[0].arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

locals {
  alarm_topic_arn = var.alarm_sns_topic_arn != null ? var.alarm_sns_topic_arn : aws_sns_topic.alarms[0].arn
}

# ALARM 1 — ALB 5xx RATE ABOVE 1%

resource "aws_cloudwatch_metric_alarm" "alb_5xx_rate" {
  alarm_name          = "${var.project_name}-${var.environment}-alb-5xx-rate"
  alarm_description   = "ALB target 5xx error rate above 1%"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 1
  evaluation_periods  = 3
  datapoints_to_alarm = 2
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "error_rate"
    expression  = "(errors / requests) * 100"
    label       = "5xx Error Rate (%)"
    return_data = true
  }

  metric_query {
    id = "errors"
    metric {
      namespace   = "AWS/ApplicationELB"
      metric_name = "HTTPCode_Target_5XX_Count"
      period      = 60
      stat        = "Sum"
      dimensions = {
        LoadBalancer = var.alb_arn_suffix
      }
    }
  }

  metric_query {
    id = "requests"
    metric {
      namespace   = "AWS/ApplicationELB"
      metric_name = "RequestCount"
      period      = 60
      stat        = "Sum"
      dimensions = {
        LoadBalancer = var.alb_arn_suffix
      }
    }
  }

  alarm_actions = [local.alarm_topic_arn]
  ok_actions    = [local.alarm_topic_arn]

  tags = local.common_tags
}

# ALARM 2 — ECS RUNNING TASK COUNT BELOW MINIMUM

resource "aws_cloudwatch_metric_alarm" "ecs_task_count_low" {
  alarm_name          = "${var.project_name}-${var.environment}-ecs-task-count-low"
  alarm_description   = "ECS running task count below minimum of ${var.ecs_min_task_count}"
  namespace           = "ECS/ContainerInsights"
  metric_name         = "RunningTaskCount"
  comparison_operator = "LessThanThreshold"
  threshold           = var.ecs_min_task_count
  period              = 60
  evaluation_periods  = 3
  datapoints_to_alarm = 2
  statistic           = "Average"
  treat_missing_data  = "breaching"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  alarm_actions = [local.alarm_topic_arn]
  ok_actions    = [local.alarm_topic_arn]

  tags = local.common_tags
}

# ALARM 3 — AURORA REPLICA LAG ABOVE 30 SECONDS

resource "aws_cloudwatch_metric_alarm" "aurora_replica_lag" {
  alarm_name          = "${var.project_name}-${var.environment}-aurora-replica-lag"
  alarm_description   = "Aurora replica lag above 30 seconds"
  namespace           = "AWS/RDS"
  metric_name         = "AuroraReplicaLag"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 30000 # milliseconds
  period              = 60
  evaluation_periods  = 3
  datapoints_to_alarm = 2
  statistic           = "Maximum"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBClusterIdentifier = var.database_cluster_id
  }

  alarm_actions = [local.alarm_topic_arn]
  ok_actions    = [local.alarm_topic_arn]

  tags = local.common_tags
}

# ALARM 4 — ELASTICACHE MEMORY ABOVE 80%

resource "aws_cloudwatch_metric_alarm" "elasticache_memory" {
  alarm_name          = "${var.project_name}-${var.environment}-elasticache-memory"
  alarm_description   = "ElastiCache Redis memory usage above 80%"
  namespace           = "AWS/ElastiCache"
  metric_name         = "DatabaseMemoryUsagePercentage"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 80
  period              = 60
  evaluation_periods  = 3
  datapoints_to_alarm = 2
  statistic           = "Average"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ReplicationGroupId = var.elasticache_replication_group_id
  }

  alarm_actions = [local.alarm_topic_arn]
  ok_actions    = [local.alarm_topic_arn]

  tags = local.common_tags
}

# ALARM 5 — RDS PROXY CONNECTIONS ABOVE 80% OF MAX

resource "aws_cloudwatch_metric_alarm" "rds_proxy_connections" {
  alarm_name          = "${var.project_name}-${var.environment}-rds-proxy-connections"
  alarm_description   = "RDS Proxy connections above ${var.rds_proxy_max_connections_percent}% of max (${var.rds_proxy_max_connections} connections)"
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.rds_proxy_max_connections_percent
  evaluation_periods  = 3
  datapoints_to_alarm = 2
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "connection_pct"
    expression  = "(in_use / ${var.rds_proxy_max_connections}) * 100"
    label       = "Proxy Connections (% of max)"
    return_data = true
  }

  metric_query {
    id = "in_use"
    metric {
      namespace   = "AWS/RDS"
      metric_name = "DatabaseConnectionsCurrentlyInUse"
      period      = 60
      stat        = "Average"
      dimensions = {
        ProxyName = var.rds_proxy_name
      }
    }
  }

  alarm_actions = [local.alarm_topic_arn]
  ok_actions    = [local.alarm_topic_arn]

  tags = local.common_tags
}

# DASHBOARDS — PER TIER + EXECUTIVE VIEW

resource "aws_cloudwatch_dashboard" "alb" {
  dashboard_name = "${var.project_name}-${var.environment}-alb"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        x = 0, y = 0, width = 12, height = 6
        properties = {
          title  = "ALB Request Count / 5xx"
          region = var.aws_region
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix],
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", var.alb_arn_suffix]
          ]
          period = 60
          stat   = "Sum"
        }
      }
    ]
  })
}

resource "aws_cloudwatch_dashboard" "ecs" {
  dashboard_name = "${var.project_name}-${var.environment}-ecs"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        x = 0, y = 0, width = 12, height = 6
        properties = {
          title  = "ECS CPU / Memory / Running Tasks"
          region = var.aws_region
          metrics = [
            ["ECS/ContainerInsights", "CpuUtilized", "ClusterName", var.ecs_cluster_name, "ServiceName", var.ecs_service_name],
            ["ECS/ContainerInsights", "MemoryUtilized", "ClusterName", var.ecs_cluster_name, "ServiceName", var.ecs_service_name],
            ["ECS/ContainerInsights", "RunningTaskCount", "ClusterName", var.ecs_cluster_name, "ServiceName", var.ecs_service_name]
          ]
          period = 60
          stat   = "Average"
        }
      }
    ]
  })
}

resource "aws_cloudwatch_dashboard" "aurora" {
  dashboard_name = "${var.project_name}-${var.environment}-aurora"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        x = 0, y = 0, width = 12, height = 6
        properties = {
          title  = "Aurora Replica Lag / Proxy Connections"
          region = var.aws_region
          metrics = [
            ["AWS/RDS", "AuroraReplicaLag", "DBClusterIdentifier", var.database_cluster_id],
            ["AWS/RDS", "DatabaseConnectionsCurrentlyInUse", "ProxyName", var.rds_proxy_name]
          ]
          period = 60
          stat   = "Average"
        }
      }
    ]
  })
}

resource "aws_cloudwatch_dashboard" "elasticache" {
  dashboard_name = "${var.project_name}-${var.environment}-elasticache"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        x = 0, y = 0, width = 12, height = 6
        properties = {
          title  = "ElastiCache Memory / CPU"
          region = var.aws_region
          metrics = [
            ["AWS/ElastiCache", "DatabaseMemoryUsagePercentage", "ReplicationGroupId", var.elasticache_replication_group_id],
            ["AWS/ElastiCache", "EngineCPUUtilization", "ReplicationGroupId", var.elasticache_replication_group_id]
          ]
          period = 60
          stat   = "Average"
        }
      }
    ]
  })
}

resource "aws_cloudwatch_dashboard" "executive" {
  dashboard_name = "${var.project_name}-${var.environment}-executive"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        x = 0, y = 0, width = 8, height = 6
        properties = {
          title   = "ALB 5xx Rate"
          region  = var.aws_region
          metrics = [["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", var.alb_arn_suffix]]
          period  = 60
          stat    = "Sum"
        }
      },
      {
        type = "metric"
        x = 8, y = 0, width = 8, height = 6
        properties = {
          title   = "ECS Running Tasks"
          region  = var.aws_region
          metrics = [["ECS/ContainerInsights", "RunningTaskCount", "ClusterName", var.ecs_cluster_name, "ServiceName", var.ecs_service_name]]
          period  = 60
          stat    = "Average"
        }
      },
      {
        type = "metric"
        x = 16, y = 0, width = 8, height = 6
        properties = {
          title   = "Aurora Replica Lag"
          region  = var.aws_region
          metrics = [["AWS/RDS", "AuroraReplicaLag", "DBClusterIdentifier", var.database_cluster_id]]
          period  = 60
          stat    = "Maximum"
        }
      }
    ]
  })
}
