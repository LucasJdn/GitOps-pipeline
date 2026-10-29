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

variable "min_capacity" {
  description = "Minimum number of tasks for the ECS service"
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Maximum number of tasks for the ECS service"
  type        = number
  default     = 8
}

variable "cpu_target_value" {
  description = "Target average CPU utilization percentage to trigger scaling"
  type        = number
  default     = 60.0
}

variable "scale_in_cooldown" {
  description = "Cooldown period in seconds before allowing another scale-in action"
  type        = number
  default     = 300
}

variable "scale_out_cooldown" {
  description = "Cooldown period in seconds before allowing another scale-out action"
  type        = number
  default     = 60
}

variable "enable_memory_scaling" {
  description = "Whether to enable memory utilization target tracking scaling"
  type        = bool
  default     = true
}

variable "memory_target_value" {
  description = "Target average Memory utilization percentage to trigger scaling"
  type        = number
  default     = 80.0
}
