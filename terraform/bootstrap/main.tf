# ------------------------------------------------------------------------------
# Terraform Configuration
# ------------------------------------------------------------------------------

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
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

# ------------------------------------------------------------------------------
# Data Sources
# ------------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

# ------------------------------------------------------------------------------
# OIDC Subject Patterns
#
# GitHub stamps the numeric owner/repository IDs onto the `sub` claim, which
# makes it stable across renames and transfers:
#
#   repo:<owner>@<owner_id>/<repo>@<repo_id>:ref:refs/heads/main
#   repo:<owner>@<owner_id>/<repo>@<repo_id>:pull_request
#
# The legacy `repo:<owner>/<repo>:<context>` form is kept as well because both
# formats can be issued while the rollout progresses.
#
# Only the two contexts the workflows actually need are trusted: pushes to main
# (deploy and manual teardown) and pull requests (plan only). A fork pull
# request carries the same `:pull_request` subject as an internal one, so the
# workflows additionally refuse to hand out credentials to forks.
# ------------------------------------------------------------------------------

locals {
  github_repo_parts = split("/", var.github_repo)
  github_owner      = local.github_repo_parts[0]
  github_repo_name  = local.github_repo_parts[1]

  github_trusted_contexts = [
    "ref:refs/heads/main",
    "pull_request",
  ]

  github_subject_prefixes = [
    "repo:${local.github_owner}@${var.github_owner_id}/${local.github_repo_name}@${var.github_repo_id}",
    "repo:${local.github_owner}/${local.github_repo_name}",
  ]

  github_subject_claims = flatten([
    for prefix in local.github_subject_prefixes : [
      for context in local.github_trusted_contexts : "${prefix}:${context}"
    ]
  ])
}

# ------------------------------------------------------------------------------
# Remote State Storage S3
# ------------------------------------------------------------------------------

resource "aws_s3_bucket" "terraform_state" {
  bucket        = "${var.project_name}-terraform-state-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ------------------------------------------------------------------------------
# State Locking DynamoDB
# ------------------------------------------------------------------------------

resource "aws_dynamodb_table" "terraform_lock" {
  name         = "${var.project_name}-terraform-lock"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

# ------------------------------------------------------------------------------
# OIDC Identity Provider (Github actions)
# ------------------------------------------------------------------------------

resource "aws_iam_openid_connect_provider" "github_actions" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f8d704f620"
  ]
}

# ------------------------------------------------------------------------------
# IAM Roles (GitHub Actions OIDC)
#
# One role per job, so a compromised deploy step cannot rebuild infrastructure
# and vice versa:
#
#   infra  (terraform job) -> plan/apply the whole stack
#   deploy (deploy job)    -> register a task definition revision and trigger
#                             the CodeDeploy blue/green deployment
#
# Every resource the pipeline may touch is named after the project, which is
# what makes ARN-level scoping possible instead of "Resource": "*".
# ------------------------------------------------------------------------------

locals {
  github_trust_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = local.github_subject_claims
          }
        }
      }
    ]
  })

  account_id = data.aws_caller_identity.current.account_id

  project_role_arns = "arn:aws:iam::${local.account_id}:role/${var.project_name}-*"

  ecr_repository_arn = "arn:aws:ecr:${var.aws_region}:${local.account_id}:repository/${var.project_name}-*"

  ecs_task_definition_arn = "arn:aws:ecs:${var.aws_region}:${local.account_id}:task-definition/${var.project_name}-*"

  ecs_service_arns = [
    "arn:aws:ecs:${var.aws_region}:${local.account_id}:service/${var.project_name}-*/*",
  ]

  ecs_resource_arns = concat(
    [
      "arn:aws:ecs:${var.aws_region}:${local.account_id}:cluster/${var.project_name}-*",
      local.ecs_task_definition_arn,
    ],
    local.ecs_service_arns,
  )

  codedeploy_app_arn              = "arn:aws:codedeploy:${var.aws_region}:${local.account_id}:application:${var.project_name}-*"
  codedeploy_deployment_group_arn = "arn:aws:codedeploy:${var.aws_region}:${local.account_id}:deploymentgroup:${var.project_name}-*/*"
  # The deployment config is an AWS-managed CodeDeployDefault.* (see the
  # codedeploy module), it cannot be renamed per project.
  codedeploy_deployment_config_arn = "arn:aws:codedeploy:${var.aws_region}:${local.account_id}:deploymentconfig:CodeDeployDefault.*"

  ecs_task_role_arns = [
    "arn:aws:iam::${local.account_id}:role/${var.project_name}-${var.environment}-ecs-execution-role",
    "arn:aws:iam::${local.account_id}:role/${var.project_name}-${var.environment}-ecs-task-role",
  ]
}

resource "aws_iam_role" "github_actions" {
  name               = "${var.project_name}-github-actions-oidc-role"
  description        = "Terraform plan/apply for the ${var.project_name} pipeline (GitHub Actions OIDC)"
  assume_role_policy = local.github_trust_policy
}

resource "aws_iam_role" "github_actions_deploy" {
  name               = "${var.project_name}-github-actions-deploy-role"
  description        = "Narrow role for the CodeDeploy blue/green job (GitHub Actions OIDC)"
  assume_role_policy = local.github_trust_policy
}

# ------------------------------------------------------------------------------
# IAM Policy (infra role - Terraform)
#
# Deliberately NOT granted: account-wide s3, unrestricted iam:PassRole and
# iam:CreateRole on "*". Those three turn a pipeline compromise into account
# takeover (create an admin role, pass it to an ECS task, run it).
# ------------------------------------------------------------------------------

resource "aws_iam_role_policy" "github_actions_permissions" {
  name = "${var.project_name}-github-actions-policy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "EcrLogin"
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Sid    = "EcrProjectRepository"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeRepositories",
          "ecr:CreateRepository",
          "ecr:DeleteRepository",
          "ecr:TagResource",
          "ecr:UntagResource",
          "ecr:ListTagsForResource",
          "ecr:PutLifecyclePolicy",
          "ecr:GetLifecyclePolicy",
          "ecr:DeleteLifecyclePolicy",
          "ecr:PutImageScanningConfiguration",
          "ecr:PutImageTagMutability",
          "ecr:BatchDeleteImage",
          "ecr:ListImages",
          "ecr:DescribeImages"
        ]
        Resource = local.ecr_repository_arn
      },
      {
        Sid      = "EcsProjectResources"
        Effect   = "Allow"
        Action   = ["ecs:*"]
        Resource = local.ecs_resource_arns
      },
      {
        Sid    = "EcsReadOnly"
        Effect = "Allow"
        Action = [
          "ecs:ListClusters",
          "ecs:ListServices",
          "ecs:ListTaskDefinitions",
          "ecs:DescribeClusters",
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition",
          "ecs:ListTagsForResource"
        ]
        Resource = "*"
      },
      {
        Sid      = "CodeDeployProjectResources"
        Effect   = "Allow"
        Action   = ["codedeploy:*"]
        Resource = [local.codedeploy_app_arn, local.codedeploy_deployment_group_arn, local.codedeploy_deployment_config_arn]
      },
      {
        Sid    = "CodeDeployReadOnly"
        Effect = "Allow"
        Action = [
          "codedeploy:ListApplications",
          "codedeploy:ListDeploymentGroups",
          "codedeploy:ListDeploymentConfigs",
          "codedeploy:ListDeployments",
          "codedeploy:BatchGetApplications",
          "codedeploy:BatchGetDeploymentGroups",
          "codedeploy:BatchGetDeploymentTargets"
        ]
        Resource = "*"
      },
      {
        Sid      = "TerraformStateBucket"
        Effect   = "Allow"
        Action   = ["s3:ListBucket", "s3:GetBucketVersioning", "s3:GetBucketLocation"]
        Resource = aws_s3_bucket.terraform_state.arn
      },
      {
        Sid      = "TerraformStateObjects"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "${aws_s3_bucket.terraform_state.arn}/*"
      },
      {
        Sid      = "TerraformStateLock"
        Effect   = "Allow"
        Action   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem", "dynamodb:DescribeTable"]
        Resource = aws_dynamodb_table.terraform_lock.arn
      },
      {
        Sid    = "ProjectRolesOnly"
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:GetRolePolicy",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:ListInstanceProfilesForRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:UpdateAssumeRolePolicy"
        ]
        Resource = local.project_role_arns
      },
      {
        Sid      = "PassRoleToAwsServicesOnly"
        Effect   = "Allow"
        Action   = ["iam:PassRole"]
        Resource = local.project_role_arns
        Condition = {
          StringEquals = {
            "iam:PassedToService" = [
              "ecs-tasks.amazonaws.com",
              "ecs.amazonaws.com",
              "codedeploy.amazonaws.com"
            ]
          }
        }
      },
      {
        Sid      = "CreateServiceLinkedRoles"
        Effect   = "Allow"
        Action   = ["iam:CreateServiceLinkedRole"]
        Resource = "*"
        Condition = {
          StringEquals = {
            "iam:AWSServiceName" = [
              "ecs.amazonaws.com",
              "ecs.application-autoscaling.amazonaws.com",
              "elasticloadbalancing.amazonaws.com"
            ]
          }
        }
      },
      {
        Sid      = "ReadAwsManagedPolicies"
        Effect   = "Allow"
        Action   = ["iam:GetPolicy", "iam:GetPolicyVersion"]
        Resource = "*"
      },
      {
        Sid    = "MonitoringProjectResources"
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricAlarm",
          "cloudwatch:DeleteAlarms",
          "cloudwatch:TagResource",
          "cloudwatch:UntagResource",
          "sns:CreateTopic",
          "sns:DeleteTopic",
          "sns:GetTopicAttributes",
          "sns:SetTopicAttributes",
          "sns:Subscribe",
          "sns:Unsubscribe",
          "sns:ListSubscriptionsByTopic",
          "sns:TagResource",
          "sns:UntagResource"
        ]
        Resource = [
          "arn:aws:cloudwatch:${var.aws_region}:${local.account_id}:alarm:${var.project_name}-*",
          "arn:aws:sns:${var.aws_region}:${local.account_id}:${var.project_name}-*"
        ]
      },
      {
        Sid    = "LogsProjectResources"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:DeleteLogGroup",
          "logs:PutRetentionPolicy",
          "logs:TagResource",
          "logs:UntagResource",
          "logs:ListTagsForResource"
        ]
        Resource = [
          "arn:aws:logs:${var.aws_region}:${local.account_id}:log-group:/ecs/${var.project_name}-*",
          "arn:aws:logs:${var.aws_region}:${local.account_id}:log-group:/ecs/${var.project_name}-*:*"
        ]
      },
      {
        # These APIs do not support resource-level permissions (IAM reports no
        # resource type for them), so "*" is required. They are read-only.
        Sid    = "ReadOnlyServiceDiscovery"
        Effect = "Allow"
        Action = [
          "cloudwatch:DescribeAlarms",
          "cloudwatch:DescribeAlarmHistory",
          "logs:DescribeLogGroups",
          "sns:ListTagsForResource"
        ]
        Resource = "*"
      },
      {
        Sid    = "NetworkAndComputeProvisioning"
        Effect = "Allow"
        Action = [
          "ec2:*",
          "elasticloadbalancing:*",
          "autoscaling:*",
          "application-autoscaling:*"
        ]
        # VPC, ALB, listeners, target groups and scalable targets are created
        # from scratch on every apply, so they cannot be pinned to existing
        # ARNs. This is the documented trade-off of applying infrastructure
        # from CI (see README "Security considerations").
        Resource = "*"
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# IAM Policy (deploy role - CodeDeploy blue/green only)
#
# Read the active task definition, register a new revision, start the
# deployment and poll it. Nothing here can create or delete infrastructure.
# ------------------------------------------------------------------------------

resource "aws_iam_role_policy" "github_actions_deploy_permissions" {
  name = "${var.project_name}-github-actions-deploy-policy"
  role = aws_iam_role.github_actions_deploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "RegisterTaskDefinitionRevision"
        Effect = "Allow"
        Action = [
          "ecs:DescribeTaskDefinition",
          "ecs:RegisterTaskDefinition",
          "ecs:TagResource"
        ]
        Resource = local.ecs_task_definition_arn
      },
      {
        Sid      = "DescribeService"
        Effect   = "Allow"
        Action   = ["ecs:DescribeServices"]
        Resource = local.ecs_service_arns
      },
      {
        Sid    = "TriggerBlueGreenDeployment"
        Effect = "Allow"
        Action = [
          "codedeploy:CreateDeployment",
          "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentTarget",
          "codedeploy:GetDeploymentGroup",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:GetApplication",
          "codedeploy:ListDeploymentTargets",
          "codedeploy:ListDeployments"
        ]
        Resource = [local.codedeploy_app_arn, local.codedeploy_deployment_group_arn, local.codedeploy_deployment_config_arn]
      },
      {
        Sid      = "PassEcsRolesToEcsTasksOnly"
        Effect   = "Allow"
        Action   = ["iam:PassRole"]
        Resource = local.ecs_task_role_arns
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "ecs-tasks.amazonaws.com"
          }
        }
      }
    ]
  })
}
