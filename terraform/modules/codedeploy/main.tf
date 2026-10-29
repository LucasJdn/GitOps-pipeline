# ------------------------------------------------------------------------------
# IAM Role for CodeDeploy
# ------------------------------------------------------------------------------

resource "aws_iam_role" "codedeploy" {
  name = "${var.project_name}-${var.environment}-codedeploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-codedeploy-role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "codedeploy" {
  role       = aws_iam_role.codedeploy.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}

# ------------------------------------------------------------------------------
# CodeDeploy Application (ECS Compute Platform)
# ------------------------------------------------------------------------------

resource "aws_codedeploy_app" "app" {
  compute_platform = "ECS"
  name             = "${var.project_name}-${var.environment}-codedeploy-app"

  tags = {
    Name        = "${var.project_name}-${var.environment}-codedeploy-app"
    Environment = var.environment
  }
}

# ------------------------------------------------------------------------------
# CodeDeploy Deployment Group (Blue/Green for ECS)
# ------------------------------------------------------------------------------

resource "aws_codedeploy_deployment_group" "app" {
  app_name               = aws_codedeploy_app.app.name
  deployment_group_name  = "${var.project_name}-${var.environment}-deployment-group"
  service_role_arn       = aws_iam_role.codedeploy.arn
  deployment_config_name = var.deployment_config_name

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_ALARM"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout    = var.action_on_timeout
      wait_time_in_minutes = var.action_on_timeout == "STOP_DEPLOYMENT" ? var.wait_time_in_minutes : null
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = var.termination_wait_time_in_minutes
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = var.ecs_cluster_name
    service_name = var.ecs_service_name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [var.prod_listener_arn]
      }

      test_traffic_route {
        listener_arns = [var.test_listener_arn]
      }

      target_group {
        name = var.blue_target_group_name
      }

      target_group {
        name = var.green_target_group_name
      }
    }
  }

  dynamic "alarm_configuration" {
    for_each = length(var.alarm_names) > 0 ? [1] : []
    content {
      alarms  = var.alarm_names
      enabled = true
    }
  }

  dynamic "trigger_configuration" {
    for_each = var.sns_topic_arn != null ? [1] : []
    content {
      trigger_events     = ["DeploymentFailure", "DeploymentSuccess", "DeploymentStop"]
      trigger_name       = "${var.project_name}-${var.environment}-deployment-trigger"
      trigger_target_arn = var.sns_topic_arn
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.codedeploy
  ]

  tags = {
    Name        = "${var.project_name}-${var.environment}-deployment-group"
    Environment = var.environment
  }
}
