variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
}

variable "environment" {
  description = "Environment name for resource tagging (e.g., prod, staging)"
  type        = string
}

variable "aws_region" {
  description = "AWS region for CloudWatch logs"
  type        = string
  default     = "us-east-1"
}

variable "private_subnets" {
  description = "List of private subnet IDs where ECS tasks will run"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "Security group ID for ECS tasks"
  type        = string
}

variable "target_group_arn" {
  description = "ARN of the initial ALB target group (Blue) to attach to the ECS service"
  type        = string
}

variable "container_name" {
  description = "Name of the container inside the task definition"
  type        = string
  default     = "app"
}

variable "container_image" {
  description = "Docker image URI to deploy in the ECS task"
  type        = string
}

variable "container_port" {
  description = "Port exposed by the container application"
  type        = number
  default     = 3000
}

variable "cpu" {
  description = "CPU units allocated for the Fargate task (e.g., 256, 512, 1024)"
  type        = string
  default     = "512"
}

variable "memory" {
  description = "Memory allocated for the Fargate task in MiB (e.g., 512, 1024, 2048)"
  type        = string
  default     = "1024"
}

variable "desired_count" {
  description = "Desired number of task instances running in the ECS service"
  type        = number
  default     = 2
}

variable "log_retention_days" {
  description = "Retention period in days for CloudWatch log events"
  type        = number
  default     = 7
}

variable "environment_variables" {
  description = "Environment variables to pass to the container definition"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}
