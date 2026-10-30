# ------------------------------------------------------------------------------
# ECS Service Alarms (CPU & Memory)
# ------------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  alarm_name          = "${var.project_name}-${var.environment}-ecs-cpu-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = var.period
  statistic           = "Average"
  threshold           = var.cpu_high_threshold
  alarm_description   = "Alarm when ECS CPU utilization exceeds ${var.cpu_high_threshold}%"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-ecs-cpu-high"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_metric_alarm" "ecs_memory_high" {
  alarm_name          = "${var.project_name}-${var.environment}-ecs-memory-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.evaluation_periods
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = var.period
  statistic           = "Average"
  threshold           = var.memory_high_threshold
  alarm_description   = "Alarm when ECS Memory utilization exceeds ${var.memory_high_threshold}%"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-ecs-memory-high"
    Environment = var.environment
  }
}

# ------------------------------------------------------------------------------
# ALB HTTP 5XX & Target Error Alarms
# ------------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  alarm_name          = "${var.project_name}-${var.environment}-alb-5xx-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.evaluation_periods
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = var.period
  statistic           = "Sum"
  threshold           = var.alb_5xx_threshold
  alarm_description   = "Alarm when ALB target returns 5XX responses exceeding threshold"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-alb-5xx-errors"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_blue_5xx_errors" {
  alarm_name          = "${var.project_name}-${var.environment}-alb-blue-5xx-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.evaluation_periods
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = var.period
  statistic           = "Sum"
  threshold           = var.alb_5xx_threshold
  alarm_description   = "Alarm when Blue target group returns 5XX errors"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.blue_target_group_arn_suffix
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-alb-blue-5xx-errors"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_green_5xx_errors" {
  alarm_name          = "${var.project_name}-${var.environment}-alb-green-5xx-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.evaluation_periods
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = var.period
  statistic           = "Sum"
  threshold           = var.alb_5xx_threshold
  alarm_description   = "Alarm when Green target group returns 5XX errors during deployment"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.green_target_group_arn_suffix
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-alb-green-5xx-errors"
    Environment = var.environment
  }
}
