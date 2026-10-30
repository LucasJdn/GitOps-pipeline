variable "aws_region" {
  description = "AWS region for infrastructure provisioning"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name for resource tagging and identification"
  type        = string
  default     = "project05"
}

variable "environment" {
  description = "Deployment environment (e.g., prod, staging, dev)"
  type        = string
  default     = "production"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.5.0.0/16"
}

variable "container_image" {
  description = "Container image URI for the ECS task definition. When null, uses '<ecr_repository_url>:latest'"
  type        = string
  default     = null
}

variable "container_port" {
  description = "Port exposed by the container application"
  type        = number
  default     = 3000
}

variable "alert_email" {
  description = "Optional alert email recipient for SNS deployment notifications"
  type        = string
  default     = null
}
