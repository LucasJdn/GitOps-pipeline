variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project Name"
  type        = string
  default     = "project05"
}

variable "github_repo" {
  description = "Github Repository"
  type        = string
  default     = "LucasJdn/GitOps-pipeline"
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "production"
}