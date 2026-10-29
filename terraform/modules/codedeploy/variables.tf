variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
}

variable "environment" {
  description = "Environment name for resource tagging (e.g., prod, staging)"
  type        = string
}

variable "ecs_cluster_name" {
  description = "Name of the ECS Cluster"
  type        = string
}

variable "ecs_service_name" {
  description = "Name of the ECS Service"
  type        = string
}

variable "prod_listener_arn" {
  description = "ARN of the production listener (port 80)"
  type        = string
}

variable "test_listener_arn" {
  description = "ARN of the test listener (port 8080)"
  type        = string
}

variable "blue_target_group_name" {
  description = "Name of the Blue target group"
  type        = string
}

variable "green_target_group_name" {
  description = "Name of the Green target group"
  type        = string
}

variable "deployment_config_name" {
  description = "CodeDeploy deployment configuration name (e.g., CodeDeployDefault.ECSLinear10PercentEvery1Minutes)"
  type        = string
  default     = "CodeDeployDefault.ECSLinear10PercentEvery1Minutes"
}

variable "termination_wait_time_in_minutes" {
  description = "Time in minutes to wait before terminating the original (Blue) task set after deployment succeeds"
  type        = number
  default     = 5
}

variable "action_on_timeout" {
  description = "Action on timeout for deployment ready option (CONTINUE_DEPLOYMENT or STOP_DEPLOYMENT)"
  type        = string
  default     = "CONTINUE_DEPLOYMENT"
}

variable "wait_time_in_minutes" {
  description = "Minutes to wait before stopping deployment if action_on_timeout is STOP_DEPLOYMENT"
  type        = number
  default     = 0
}

variable "alarm_names" {
  description = "List of CloudWatch alarm names to trigger automatic rollback"
  type        = list(string)
  default     = []
}

variable "sns_topic_arn" {
  description = "Optional SNS topic ARN for deployment trigger notifications"
  type        = string
  default     = null
}
