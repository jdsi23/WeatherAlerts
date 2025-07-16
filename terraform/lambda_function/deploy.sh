#!/bin/bash
set -e

curl -O https://releases.hashicorp.com/terraform/1.7.5/terraform_1.7.5_linux_amd64.zip
unzip -o terraform_1.7.5_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Check dependencies
for cmd in aws terraform docker zip sed; do
  if ! command -v $cmd &> /dev/null; then
    echo "Error: $cmd is not installed."
    exit 1
  fi
done

if [ -z "$1" ] && [ -z "$WEATHER_API_KEY" ]; then
  echo "Usage: $0 <weather_api_key>"
  echo "Or set WEATHER_API_KEY environment variable."
  exit 1
fi

API_KEY="${1:-$WEATHER_API_KEY}"

REGION="us-east-1"
LAMBDA_ZIP="lambda_function.zip"
DOCKER_IMAGE_NAME="weatheralerts-app"
DOCKER_IMAGE_TAG="latest"
ECR_REPO_NAME="weatheralerts-repo"
BUCKET_NAME="weatheralerts-data-bucket-$(date +%s)"
LAMBDA_FUNCTION_NAME="weather-data-refresh-lambda"
ECS_CLUSTER_NAME="weatheralerts-ecs-cluster"
ECS_SERVICE_NAME="weatheralerts-ecs-service"

echo "Packaging Lambda function..."
zip -r $LAMBDA_ZIP lambda_function.py

echo "Initializing Terraform..."
terraform init

echo "Creating terraform.tfvars..."
cat > terraform.tfvars << EOF
region = "$REGION"
bucket_name = "$BUCKET_NAME"
lambda_function_name = "$LAMBDA_FUNCTION_NAME"
ecs_cluster_name = "$ECS_CLUSTER_NAME"
ecs_service_name = "$ECS_SERVICE_NAME"
container_image = ""
weather_api_key = "$API_KEY"
EOF

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REPO_URI="$AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO_NAME"

echo "Creating ECR repository (if needed)..."
aws ecr create-repository --repository-name $ECR_REPO_NAME --region $REGION || true

echo "Logging into ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_REPO_URI

echo "Building Docker image..."
docker build -t $DOCKER_IMAGE_NAME:$DOCKER_IMAGE_TAG .

echo "Tagging Docker image..."
docker tag $DOCKER_IMAGE_NAME:$DOCKER_IMAGE_TAG $ECR_REPO_URI:$DOCKER_IMAGE_TAG

echo "Pushing Docker image..."
docker push $ECR_REPO_URI:$DOCKER_IMAGE_TAG

echo "Updating terraform.tfvars with container image URI..."
sed -i "s|container_image = .*|container_image = \"$ECR_REPO_URI:$DOCKER_IMAGE_TAG\"|" terraform.tfvars

echo "Applying Terraform..."
terraform apply -auto-approve

echo "Deployment complete."
echo "S3 Bucket: $BUCKET_NAME"
echo "Lambda Function: $LAMBDA_FUNCTION_NAME"
echo "ECS Service: $ECS_SERVICE_NAME in cluster $ECS_CLUSTER_NAME"
echo "Docker Image URI: $ECR_REPO_URI:$DOCKER_IMAGE_TAG"
