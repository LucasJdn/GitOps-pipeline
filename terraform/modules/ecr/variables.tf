variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
}

variable "environment" {
  description = "Environment name for resource tagging (e.g., prod, staging)"
  type        = string
}

variable "image_retention_count" {
  description = "Number of Docker images to retain in ECR"
  type        = number
  default     = 5
}
