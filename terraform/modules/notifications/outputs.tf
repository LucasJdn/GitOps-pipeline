output "topic_arn" {
  description = "The ARN of the SNS alerts topic"
  value       = aws_sns_topic.alerts.arn
}

output "topic_name" {
  description = "The name of the SNS alerts topic"
  value       = aws_sns_topic.alerts.name
}

output "topic_id" {
  description = "The ID of the SNS alerts topic"
  value       = aws_sns_topic.alerts.id
}
