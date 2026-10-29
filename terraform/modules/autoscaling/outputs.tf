output "autoscaling_target_id" {
  description = "The ID of the ECS App Auto Scaling target"
  value       = aws_appautoscaling_target.ecs.id
}

output "autoscaling_target_resource_id" {
  description = "The resource ID of the ECS App Auto Scaling target"
  value       = aws_appautoscaling_target.ecs.resource_id
}

output "cpu_policy_arn" {
  description = "The ARN of the CPU target tracking scaling policy"
  value       = aws_appautoscaling_policy.ecs_cpu.arn
}

output "cpu_policy_name" {
  description = "The name of the CPU target tracking scaling policy"
  value       = aws_appautoscaling_policy.ecs_cpu.name
}

output "memory_policy_arn" {
  description = "The ARN of the Memory target tracking scaling policy"
  value       = try(aws_appautoscaling_policy.ecs_memory[0].arn, null)
}

output "memory_policy_name" {
  description = "The name of the Memory target tracking scaling policy"
  value       = try(aws_appautoscaling_policy.ecs_memory[0].name, null)
}

output "min_capacity" {
  description = "Configured minimum task capacity"
  value       = aws_appautoscaling_target.ecs.min_capacity
}

output "max_capacity" {
  description = "Configured maximum task capacity"
  value       = aws_appautoscaling_target.ecs.max_capacity
}
