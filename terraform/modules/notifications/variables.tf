variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
}

variable "environment" {
  description = "Environment name for resource tagging (e.g., prod, staging)"
  type        = string
}

variable "alert_email" {
  description = "Optional email address to receive SNS alert notifications"
  type        = string
  default     = null
}
