output "alb_arn" {
  description = "The ARN of the ALB"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "The DNS name of the ALB"
  value       = aws_lb.main.dns_name
}

output "blue_target_group_name" {
  description = "The name of the blue target group"
  value       = aws_lb_target_group.blue.name
}

output "blue_target_group_arn" {
  description = "The ARN of the blue target group"
  value       = aws_lb_target_group.blue.arn
}

output "green_target_group_name" {
  description = "The name of the green target group"
  value       = aws_lb_target_group.green.name
}

output "green_target_group_arn" {
  description = "The ARN of the green target group"
  value       = aws_lb_target_group.green.arn
}

output "prod_listener_arn" {
  description = "The ARN of the production listener"
  value       = aws_lb_listener.prod.arn
}

output "test_listener_arn" {
  description = "The ARN of the test listener"
  value       = aws_lb_listener.test.arn
}
