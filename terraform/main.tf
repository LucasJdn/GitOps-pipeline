# ==============================================================================
# Root Infrastructure Composition
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Network Module (VPC, Subnets, NAT Gateways, IGW, Route Tables)
# ------------------------------------------------------------------------------
module "network" {
  source = "./modules/network"

  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
}

# ------------------------------------------------------------------------------
# 2. Security Module (Security Groups for ALB and ECS tasks)
# ------------------------------------------------------------------------------
module "security" {
  source = "./modules/security"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.network.vpc_id
}

# ------------------------------------------------------------------------------
# 3. ECR Module (Container Registry & Retention Policy)
# ------------------------------------------------------------------------------
module "ecr" {
  source = "./modules/ecr"

  project_name = var.project_name
  environment  = var.environment
}

# ------------------------------------------------------------------------------
# 4. ALB Module (Load Balancer, Blue/Green Target Groups & Listeners)
# ------------------------------------------------------------------------------
module "alb" {
  source = "./modules/alb"

  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.network.vpc_id
  public_subnets        = module.network.public_subnets
  alb_security_group_id = module.security.alb_sg_id
}

# ------------------------------------------------------------------------------
# 5. ECS Module (Fargate Cluster, Task Definition & Blue/Green Service)
# ------------------------------------------------------------------------------
module "ecs" {
  source = "./modules/ecs"

  project_name          = var.project_name
  environment           = var.environment
  aws_region            = var.aws_region
  private_subnets       = module.network.private_subnets
  ecs_security_group_id = module.security.ecs_sg_id
  target_group_arn      = module.alb.blue_target_group_arn
  container_image       = coalesce(var.container_image, "${module.ecr.repository_url}:latest")
  container_port        = var.container_port

  environment_variables = [
    {
      name  = "ENVIRONMENT"
      value = var.environment
    },
    {
      name  = "PORT"
      value = tostring(var.container_port)
    }
  ]

  # The target group must be attached to an ALB listener before the service is created
  depends_on = [module.alb]
}

# ------------------------------------------------------------------------------
# 6. Notifications Module (SNS Topic & Alert Email Subscription)
# ------------------------------------------------------------------------------
module "notifications" {
  source = "./modules/notifications"

  project_name = var.project_name
  environment  = var.environment
  alert_email  = var.alert_email
}

# ------------------------------------------------------------------------------
# 7. Monitoring Module (CloudWatch Alarms for Rollback)
# ------------------------------------------------------------------------------
module "monitoring" {
  source = "./modules/monitoring"

  project_name                  = var.project_name
  environment                   = var.environment
  ecs_cluster_name              = module.ecs.cluster_name
  ecs_service_name              = module.ecs.service_name
  alb_arn_suffix                = module.alb.alb_arn_suffix
  blue_target_group_arn_suffix  = module.alb.blue_target_group_arn_suffix
  green_target_group_arn_suffix = module.alb.green_target_group_arn_suffix
  alarm_actions                 = [module.notifications.topic_arn]
  ok_actions                    = [module.notifications.topic_arn]
}

# ------------------------------------------------------------------------------
# 8. Auto Scaling Module (ECS Target Tracking CPU/Memory)
# ------------------------------------------------------------------------------
module "autoscaling" {
  source = "./modules/autoscaling"

  project_name     = var.project_name
  environment      = var.environment
  ecs_cluster_name = module.ecs.cluster_name
  ecs_service_name = module.ecs.service_name
}

# ------------------------------------------------------------------------------
# 9. CodeDeploy Module (Blue/Green Deployment Group with Traffic Control)
# ------------------------------------------------------------------------------
module "codedeploy" {
  source = "./modules/codedeploy"

  project_name            = var.project_name
  environment             = var.environment
  ecs_cluster_name        = module.ecs.cluster_name
  ecs_service_name        = module.ecs.service_name
  prod_listener_arn       = module.alb.prod_listener_arn
  test_listener_arn       = module.alb.test_listener_arn
  blue_target_group_name  = module.alb.blue_target_group_name
  green_target_group_name = module.alb.green_target_group_name
  alarm_names             = module.monitoring.codedeploy_rollback_alarm_names
  sns_topic_arn           = module.notifications.topic_arn
}
