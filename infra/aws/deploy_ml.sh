#!/usr/bin/env bash
# ==============================================================================
# Script: deploy_ml.sh
# Description: Builds, tags, pushes ML container to ECR, and deploys to App Runner
# ==============================================================================

set -e

REGION="${AWS_REGION:-us-east-1}"
REPO_NAME="cts-npn-ml"
SERVICE_NAME="cts-npn-ml-service"
IMAGE_TAG="latest"

echo "=== CTS-NPN: Litestar ML Model Deployment to AWS App Runner ==="

# 1. Fetch AWS Account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
echo "AWS Account ID: $ACCOUNT_ID"

ECR_URI="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME"

# 2. Ensure ECR Repository exists
aws ecr describe-repositories --repository-names "$REPO_NAME" --region "$REGION" >/dev/null 2>&1 || \
aws ecr create-repository --repository-name "$REPO_NAME" --region "$REGION"

# 3. Log in to ECR
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"

# 4. Build and push Docker image
docker build -t "$REPO_NAME:$IMAGE_TAG" -f infra/docker/ml.Dockerfile .
docker tag "$REPO_NAME:$IMAGE_TAG" "$ECR_URI:$IMAGE_TAG"
docker push "$ECR_URI:$IMAGE_TAG"

# 5. Trigger or info on App Runner
SERVICE_ARN=$(aws apprunner list-services --region "$REGION" --query "ServiceSummaryList[?ServiceName=='$SERVICE_NAME'].ServiceArn" --output text || true)

if [ -n "$SERVICE_ARN" ] && [ "$SERVICE_ARN" != "None" ]; then
    echo "Found service ARN: $SERVICE_ARN. Starting deployment..."
    aws apprunner start-deployment --service-arn "$SERVICE_ARN" --region "$REGION"
else
    echo "Service '$SERVICE_NAME' not found. Create it in AWS Console or via AWS CLI with image: $ECR_URI:$IMAGE_TAG"
fi

echo "=== Deployment script finished successfully ==="
