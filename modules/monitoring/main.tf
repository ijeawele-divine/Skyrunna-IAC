resource "aws_sns_topic" "alarms" {
  name = "skyrunna-${var.env}-alarms"

  tags = {
    Environment = var.env
  }
}

resource "aws_sns_topic_subscription" "email" {
  for_each = toset(var.alarm_email)

  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = each.value
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "skyrunna-${var.env}-alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "ALB returning 5xx errors"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]

  tags = {
    Environment = var.env
  }
}

resource "aws_cloudwatch_metric_alarm" "gateway_unhealthy_hosts" {
  alarm_name          = "skyrunna-${var.env}-gateway-unhealthy-targets"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "API gateway has unhealthy targets"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.gateway_target_group_arn_suffix
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]

  tags = {
    Environment = var.env
  }
}

resource "aws_cloudwatch_metric_alarm" "frontend_unhealthy_hosts" {
  alarm_name          = "skyrunna-${var.env}-frontend-unhealthy-targets"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "Frontend has unhealthy targets"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.frontend_target_group_arn_suffix
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]

  tags = {
    Environment = var.env
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_target_response_time" {
  alarm_name          = "skyrunna-${var.env}-high-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Average"
  threshold           = 5
  alarm_description   = "Average response time above 5 seconds"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  alarm_actions = [aws_sns_topic.alarms.arn]

  tags = {
    Environment = var.env
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "skyrunna-${var.env}-rds-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "RDS CPU above 80%"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  alarm_actions = [aws_sns_topic.alarms.arn]

  tags = {
    Environment = var.env
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_storage" {
  alarm_name          = "skyrunna-${var.env}-rds-low-storage"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 2147483648
  alarm_description   = "RDS free storage below 2GB"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  alarm_actions = [aws_sns_topic.alarms.arn]

  tags = {
    Environment = var.env
  }
}

resource "aws_cloudwatch_metric_alarm" "ecs_cpu" {
  for_each = toset(var.ecs_service_names)

  alarm_name          = "skyrunna-${var.env}-${each.key}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 85
  alarm_description   = "${each.key} CPU above 85%"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = "skyrunna-${var.env}-${each.key}"
  }

  alarm_actions = [aws_sns_topic.alarms.arn]

  tags = {
    Environment = var.env
  }
}

resource "aws_cloudwatch_metric_alarm" "ecs_memory" {
  for_each = toset(var.ecs_service_names)

  alarm_name          = "skyrunna-${var.env}-${each.key}-high-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 85
  alarm_description   = "${each.key} memory above 85%"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = "skyrunna-${var.env}-${each.key}"
  }

  alarm_actions = [aws_sns_topic.alarms.arn]

  tags = {
    Environment = var.env
  }
}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "skyrunna-${var.env}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 1
        properties = {
          markdown = "# Skyrunna ${upper(var.env)} — Platform Overview"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 1
        width  = 12
        height = 6
        properties = {
          title  = "ALB Request Count & Errors"
          region = "eu-west-2"
          period = 300
          stat   = "Sum"
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix, { label = "Requests" }],
            [".", "HTTPCode_ELB_5XX_Count", ".", ".", { label = "5xx (ALB)", color = "#d62728" }],
            [".", "HTTPCode_Target_5XX_Count", ".", ".", { label = "5xx (Target)", color = "#ff7f0e" }],
            [".", "HTTPCode_Target_4XX_Count", ".", ".", { label = "4xx", color = "#bcbd22" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 1
        width  = 12
        height = 6
        properties = {
          title  = "ALB Response Time"
          region = "eu-west-2"
          period = 300
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.alb_arn_suffix, { stat = "Average", label = "Average" }],
            ["...", { stat = "p95", label = "p95" }],
            ["...", { stat = "Maximum", label = "Max" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 7
        width  = 12
        height = 6
        properties = {
          title  = "Target Group Health"
          region = "eu-west-2"
          period = 60
          stat   = "Average"
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount", "LoadBalancer", var.alb_arn_suffix, "TargetGroup", var.gateway_target_group_arn_suffix, { label = "Gateway healthy" }],
            [".", "UnHealthyHostCount", ".", ".", ".", ".", { label = "Gateway unhealthy", color = "#d62728" }],
            [".", "HealthyHostCount", ".", ".", ".", var.frontend_target_group_arn_suffix, { label = "Frontend healthy" }],
            [".", "UnHealthyHostCount", ".", ".", ".", ".", { label = "Frontend unhealthy", color = "#ff7f0e" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 7
        width  = 12
        height = 6
        properties = {
          title  = "RDS — CPU & Connections"
          region = "eu-west-2"
          period = 300
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.rds_instance_id, { stat = "Average", label = "CPU %" }],
            [".", "DatabaseConnections", ".", ".", { stat = "Average", label = "Connections", yAxis = "right" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 13
        width  = 12
        height = 6
        properties = {
          title  = "ECS — CPU Utilization by Service"
          region = "eu-west-2"
          period = 300
          stat   = "Average"
          metrics = [
            for svc in var.ecs_service_names :
            ["AWS/ECS", "CPUUtilization", "ClusterName", var.ecs_cluster_name, "ServiceName", "skyrunna-${var.env}-${svc}", { label = svc }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 13
        width  = 12
        height = 6
        properties = {
          title  = "ECS — Memory Utilization by Service"
          region = "eu-west-2"
          period = 300
          stat   = "Average"
          metrics = [
            for svc in var.ecs_service_names :
            ["AWS/ECS", "MemoryUtilization", "ClusterName", var.ecs_cluster_name, "ServiceName", "skyrunna-${var.env}-${svc}", { label = svc }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 19
        width  = 12
        height = 6
        properties = {
          title  = "RDS — Storage & Memory"
          region = "eu-west-2"
          period = 300
          stat   = "Average"
          metrics = [
            ["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", var.rds_instance_id, { label = "Free storage (bytes)" }],
            [".", "FreeableMemory", ".", ".", { label = "Freeable memory (bytes)", yAxis = "right" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 19
        width  = 12
        height = 6
        properties = {
          title  = "ElastiCache Redis"
          region = "eu-west-2"
          period = 300
          stat   = "Average"
          metrics = [
            ["AWS/ElastiCache", "CPUUtilization", "CacheClusterId", "skyrunna-${var.env}-redis", { label = "CPU %" }],
            [".", "CurrConnections", ".", ".", { label = "Connections", yAxis = "right" }]
          ]
        }
      }
    ]
  })
}