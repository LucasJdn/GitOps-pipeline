output "terraform_state_bucket" {
  description = "Name of the S3 bucket used for Terraform state storage"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "terraform_lock_table" {
  description = "Name of the DynamoDB table used for Terraform state locking"
  value       = aws_dynamodb_table.terraform_lock.name
}

output "github_actions_role_arn" {
  description = "ARN of the IAM role used by the Terraform/CD image job (GitHub Actions OIDC)"
  value       = aws_iam_role.github_actions.arn
}

output "github_actions_deploy_role_arn" {
  description = "ARN of the narrow IAM role used by the CodeDeploy blue/green job (GitHub Actions OIDC)"
  value       = aws_iam_role.github_actions_deploy.arn
}
