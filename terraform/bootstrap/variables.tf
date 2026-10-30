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
  description = "Github Repository in the <owner>/<repository> form"
  type        = string
  default     = "LucasJdn/GitOps-pipeline"
}

variable "github_owner_id" {
  description = "Numeric GitHub ID of the repository owner (immutable OIDC sub claim)"
  type        = number
  default     = 118925207
}

variable "github_repo_id" {
  description = "Numeric GitHub ID of the repository (immutable OIDC sub claim)"
  type        = number
  default     = 1387526148
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "production"
}