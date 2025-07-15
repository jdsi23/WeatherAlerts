#!/bin/bash

set -e  # Exit immediately on any error

echo "🔍 Fetching AWS account ID..."
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION="us-east-1"

# Variables
TERRAFORM_VERSION="1.7.5"
LAMBDA_PACKAGE="deployment_package.zip"
LAMBDA_SRC_DIR="lambda_package"

# Check if WEATHER_API_KEY is set in environment
if [ -z "$WEATHER_API_KEY" ]; then
  echo "❌ ERROR: Please set the WEATHER_API_KEY environment variable before running this script."
  echo "Example: export WEATHER_API_KEY='your_actual_api_key_here'"
  exit 1
fi

echo "[+] Installing Terraform v$TERRAFORM_VERSION..."

curl -O https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
unzip -o terraform_${TERRAFORM_VERSION}_linux_amd64.zip
sudo mv terraform /usr/local/bin/
rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip

terraform version

echo "[+] Preparing Lambda deployment package..."

# Clean old package and folder
rm -rf $LAMBDA_SRC_DIR $LAMBDA_PACKAGE
mkdir $LAMBDA_SRC_DIR

# Install requests library locally into the lambda_package folder
pip install requests -t $LAMBDA_SRC_DIR/

# Copy lambda_function.py to the package folder
cp lambda_function.py $LAMBDA_SRC_DIR/

# Zip the contents of the folder (not the folder itself)
cd $LAMBDA_SRC_DIR
zip -r ../$LAMBDA_PACKAGE .
cd ..

echo "[+] Initializing and applying Terraform..."

terraform init

terraform apply -var="weather_api_key=$WEATHER_API_KEY" -auto-approve

echo "✅ Deployment complete!"
