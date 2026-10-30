# ------------------------------------------------------------------------------
# SNS Topic for CI/CD and CloudWatch Alerts
# ------------------------------------------------------------------------------

resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-${var.environment}-alerts"

  tags = {
    Name        = "${var.project_name}-${var.environment}-alerts"
    Environment = var.environment
  }
}

# ------------------------------------------------------------------------------
# SNS Topic Policy (Allows CloudWatch Alarms and CodeDeploy to publish)
# ------------------------------------------------------------------------------

resource "aws_sns_topic_policy" "alerts" {
  arn = aws_sns_topic.alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudWatchAlarmsAndCodeDeployPublish"
        Effect = "Allow"
        Principal = {
          Service = [
            "cloudwatch.amazonaws.com",
            "codedeploy.amazonaws.com"
          ]
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.alerts.arn
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# Optional Email Subscription
# ------------------------------------------------------------------------------

resource "aws_sns_topic_subscription" "email" {
  count = var.alert_email != null ? 1 : 0

  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}
