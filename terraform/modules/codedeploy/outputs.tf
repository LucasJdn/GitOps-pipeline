output "app_name" {
  description = "The name of the CodeDeploy application"
  value       = aws_codedeploy_app.app.name
}

output "app_id" {
  description = "The ID of the CodeDeploy application"
  value       = aws_codedeploy_app.app.id
}

output "app_arn" {
  description = "The ARN of the CodeDeploy application"
  value       = aws_codedeploy_app.app.arn
}

output "deployment_group_name" {
  description = "The name of the CodeDeploy deployment group"
  value       = aws_codedeploy_deployment_group.app.deployment_group_name
}

output "deployment_group_id" {
  description = "The ID of the CodeDeploy deployment group"
  value       = aws_codedeploy_deployment_group.app.deployment_group_id
}

output "deployment_group_arn" {
  description = "The ARN of the CodeDeploy deployment group"
  value       = aws_codedeploy_deployment_group.app.arn
}

output "deployment_config_name" {
  description = "The name of the deployment configuration used"
  value       = aws_codedeploy_deployment_group.app.deployment_config_name
}

output "codedeploy_role_arn" {
  description = "The ARN of the CodeDeploy IAM service role"
  value       = aws_iam_role.codedeploy.arn
}

output "codedeploy_role_name" {
  description = "The name of the CodeDeploy IAM service role"
  value       = aws_iam_role.codedeploy.name
}
