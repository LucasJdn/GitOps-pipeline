variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
}

variable "environment" {
  description = "Environment name for resource tagging (e.g., prod, staging)"
  type        = string
}

variable "ecs_cluster_name" {
  description = "Name of the ECS Cluster to monitor"
  type        = string
}

variable "ecs_service_name" {
  description = "Name of the ECS Service to monitor"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ARN suffix of the Application Load Balancer for CloudWatch metrics"
  type        = string
}

variable "blue_target_group_arn_suffix" {
  description = "ARN suffix of the Blue Target Group for CloudWatch metrics"
  type        = string
}

variable "green_target_group_arn_suffix" {
  description = "ARN suffix of the Green Target Group for CloudWatch metrics"
  type        = string
}

variable "cpu_high_threshold" {
  description = "Threshold percentage for ECS service CPU utilization alarm"
  type        = number
  default     = 85
}

variable "memory_high_threshold" {
  description = "Threshold percentage for ECS service Memory utilization alarm"
  type        = number
  default     = 85
}

variable "alb_5xx_threshold" {
  description = "Threshold count for ALB HTTP 5XX error responses alarm"
  type        = number
  default     = 10
}

variable "evaluation_periods" {
  description = "Number of periods over which data is evaluated for the alarm"
  type        = number
  default     = 2
}

variable "period" {
  description = "Period in seconds over which the specified statistic is applied"
  type        = number
  default     = 60
}

variable "alarm_actions" {
  description = "List of ARNs (e.g., SNS topic ARN) to execute when the alarm transitions to ALARM state"
  type        = list(string)
  default     = []
}

variable "ok_actions" {
  description = "List of ARNs to execute when the alarm transitions to OK state"
  type        = list(string)
  default     = []
}
