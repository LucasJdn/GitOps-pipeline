#!/usr/bin/env bash
# ==============================================================================
# CodeDeploy Blue/Green Deployment Trigger Script
# ==============================================================================

set -euo pipefail

APP_NAME="${1:-project05-production-codedeploy-app}"
DEPLOYMENT_GROUP="${2:-project05-production-deployment-group}"
TASK_DEFINITION_ARN="${3:-}"
CONTAINER_NAME="${4:-app}"
CONTAINER_PORT="${5:-3000}"

if [[ -z "${TASK_DEFINITION_ARN}" ]]; then
  echo "❌ Error: TASK_DEFINITION_ARN is required as argument 3."
  echo "Usage: $0 <app_name> <deployment_group> <task_definition_arn> [container_name] [container_port]"
  exit 1
fi

echo "🚀 Generating AppSpec specification for CodeDeploy..."

APPSPEC_CONTENT=$(cat <<EOF
version: 0.0
Resources:
  - TargetService:
      Type: AWS::ECS::Service
      Properties:
        TaskDefinition: "${TASK_DEFINITION_ARN}"
        LoadBalancerInfo:
          ContainerName: "${CONTAINER_NAME}"
          ContainerPort: ${CONTAINER_PORT}
EOF
)

APPSPEC_SHA256=$(echo -n "${APPSPEC_CONTENT}" | sha256sum | awk '{print $1}')

echo "📦 Creating AWS CodeDeploy Deployment..."
DEPLOYMENT_ID=$(aws codedeploy create-deployment \
  --application-name "${APP_NAME}" \
  --deployment-group-name "${DEPLOYMENT_GROUP}" \
  --deployment-config-name "CodeDeployDefault.ECSLinear10PercentEvery1Minutes" \
  --description "Triggered via GitOps Pipeline (commit: $(git rev-parse --short HEAD 2>/dev/null || echo 'ci'))" \
  --revision "{\"revisionType\": \"AppSpecContent\", \"appSpecContent\": {\"content\": $(echo "${APPSPEC_CONTENT}" | jq -R -s .), \"sha256\": \"${APPSPEC_SHA256}\"}}" \
  --query "deploymentId" \
  --output text)

echo "✅ Deployment created successfully! Deployment ID: ${DEPLOYMENT_ID}"
echo "⏳ Waiting for deployment to succeed..."

aws codedeploy wait deployment-successful --deployment-id "${DEPLOYMENT_ID}"
echo "🎉 Deployment ${DEPLOYMENT_ID} completed successfully!"
