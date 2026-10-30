output "ecs_cpu_high_alarm_arn" {
  description = "The ARN of the ECS CPU high CloudWatch alarm"
  value       = aws_cloudwatch_metric_alarm.ecs_cpu_high.arn
}

output "ecs_cpu_high_alarm_name" {
  description = "The name of the ECS CPU high CloudWatch alarm"
  value       = aws_cloudwatch_metric_alarm.ecs_cpu_high.alarm_name
}

output "ecs_memory_high_alarm_arn" {
  description = "The ARN of the ECS Memory high CloudWatch alarm"
  value       = aws_cloudwatch_metric_alarm.ecs_memory_high.arn
}

output "ecs_memory_high_alarm_name" {
  description = "The name of the ECS Memory high CloudWatch alarm"
  value       = aws_cloudwatch_metric_alarm.ecs_memory_high.alarm_name
}

output "alb_5xx_errors_alarm_arn" {
  description = "The ARN of the ALB 5xx errors CloudWatch alarm"
  value       = aws_cloudwatch_metric_alarm.alb_5xx_errors.arn
}

output "alb_5xx_errors_alarm_name" {
  description = "The name of the ALB 5xx errors CloudWatch alarm"
  value       = aws_cloudwatch_metric_alarm.alb_5xx_errors.alarm_name
}

output "alb_blue_5xx_errors_alarm_arn" {
  description = "The ARN of the Blue target group 5xx errors CloudWatch alarm"
  value       = aws_cloudwatch_metric_alarm.alb_blue_5xx_errors.arn
}

output "alb_blue_5xx_errors_alarm_name" {
  description = "The name of the Blue target group 5xx errors CloudWatch alarm"
  value       = aws_cloudwatch_metric_alarm.alb_blue_5xx_errors.alarm_name
}

output "alb_green_5xx_errors_alarm_arn" {
  description = "The ARN of the Green target group 5xx errors CloudWatch alarm"
  value       = aws_cloudwatch_metric_alarm.alb_green_5xx_errors.arn
}

output "alb_green_5xx_errors_alarm_name" {
  description = "The name of the Green target group 5xx errors CloudWatch alarm"
  value       = aws_cloudwatch_metric_alarm.alb_green_5xx_errors.alarm_name
}

output "codedeploy_rollback_alarm_names" {
  description = "Alarm names used for CodeDeploy automatic rollback (5xx errors only; CPU/memory alarms notify via SNS without reverting deploys)"
  value = [
    aws_cloudwatch_metric_alarm.alb_5xx_errors.alarm_name,
    aws_cloudwatch_metric_alarm.alb_green_5xx_errors.alarm_name
  ]
}
