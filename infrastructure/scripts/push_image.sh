#!/usr/bin/env bash
# Build web/ Docker image and push to the noise-to-signal ECR repository.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
AWS_PROFILE="${AWS_PROFILE:-AdministratorAccess-465836752303}"
AWS_REGION="${AWS_REGION:-eu-central-1}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
TF_DIR="${TF_DIR:-$ROOT/infrastructure/env/dev}"

cd "$TF_DIR"
REPO_URL="$(terraform output -raw ecr_repository_url)"
cd "$ROOT"

ACCOUNT_ID="$(aws sts get-caller-identity --profile "$AWS_PROFILE" --query Account --output text)"
echo "Logging in to ECR ${ACCOUNT_ID} (${AWS_REGION})..."
aws ecr get-login-password --profile "$AWS_PROFILE" --region "$AWS_REGION" \
  | docker login --username AWS --password-stdin "${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

echo "Building ${REPO_URL}:${IMAGE_TAG} from web/..."
docker build -t "${REPO_URL}:${IMAGE_TAG}" "$ROOT/web"
docker push "${REPO_URL}:${IMAGE_TAG}"
echo "Pushed ${REPO_URL}:${IMAGE_TAG}"
echo "If Lambda is already enabled, update the function to pick up the new image:"
echo "  aws lambda update-function-code --function-name \$(cd $TF_DIR && terraform output -raw function_name) --image-uri ${REPO_URL}:${IMAGE_TAG}"
