terraform {
  required_version = ">= 1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    # Backend configuration passed via backend config flags during `terraform init`:
    # -backend-config="bucket=<bucket_name>"
    # -backend-config="key=production/terraform.tfstate"
    # -backend-config="region=us-east-1"
    # -backend-config="dynamodb_table=<lock_table>"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
