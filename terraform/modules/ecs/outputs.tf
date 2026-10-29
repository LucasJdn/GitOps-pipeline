output "cluster_id" {
  description = "The ID of the ECS cluster"
  value       = aws_ecs_cluster.main.id
}

output "cluster_arn" {
  description = "The ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
}

output "cluster_name" {
  description = "The name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "service_id" {
  description = "The ID of the ECS service"
  value       = aws_ecs_service.main.id
}

output "service_name" {
  description = "The name of the ECS service"
  value       = aws_ecs_service.main.name
}

output "task_definition_arn" {
  description = "The ARN of the task definition"
  value       = aws_ecs_task_definition.app.arn
}

output "task_definition_family" {
  description = "The family of the task definition"
  value       = aws_ecs_task_definition.app.family
}

output "task_execution_role_arn" {
  description = "The ARN of the ECS task execution IAM role"
  value       = aws_iam_role.ecs_execution_role.arn
}

output "task_execution_role_name" {
  description = "The name of the ECS task execution IAM role"
  value       = aws_iam_role.ecs_execution_role.name
}

output "task_role_arn" {
  description = "The ARN of the ECS task IAM role"
  value       = aws_iam_role.ecs_task_role.arn
}

output "task_role_name" {
  description = "The name of the ECS task IAM role"
  value       = aws_iam_role.ecs_task_role.name
}

output "container_name" {
  description = "The name of the application container"
  value       = var.container_name
}

output "container_port" {
  description = "The port exposed by the application container"
  value       = var.container_port
}

output "log_group_name" {
  description = "The name of the CloudWatch log group for ECS task logs"
  value       = aws_cloudwatch_log_group.ecs.name
}

output "log_group_arn" {
  description = "The ARN of the CloudWatch log group for ECS task logs"
  value       = aws_cloudwatch_log_group.ecs.arn
}
