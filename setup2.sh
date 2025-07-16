#!/bin/bash

set -e  # Stop on any error

# === CONFIG ===
FUNCTION_NAME="weather_fetcher"
ZIP_FILE="lambda_package.zip"
ROLE_NAME="weather_lambda_role"
BUCKET_NAME="sadasdasdasd13"
REGION="us-east-1"
SCHEDULE_RULE="weather_30min_rule"
ZIP_KEY="weather_data.csv"

# === STEP 1: ZIP THE LAMBDA CODE ===
echo "📦 Zipping Lambda code..."
zip -j $ZIP_FILE lambda_function.py > /dev/null

# === STEP 2: CREATE IAM ROLE (if not exists) ===
echo "🔐 Checking IAM role..."
if aws iam get-role --role-name $ROLE_NAME > /dev/null 2>&1; then
  echo "✅ IAM role '$ROLE_NAME' already exists. Skipping creation."
else
  echo "🔧 Creating IAM role..."
  aws iam create-role \
    --role-name $ROLE_NAME \
    --assume-role-policy-document file://<(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": { "Service": "lambda.amazonaws.com" },
    "Action": "sts:AssumeRole"
  }]
}
EOF
  ) > /dev/null
fi

# === STEP 3: ATTACH POLICIES ===
echo "🔒 Attaching policies..."
aws iam attach-role-policy --role-name $ROLE_NAME \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole || true
aws iam attach-role-policy --role-name $ROLE_NAME \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess || true

# === STEP 4: WAIT FOR IAM TO PROPAGATE ===
echo "⏳ Waiting for IAM role to propagate..."
sleep 15

# === STEP 5: CREATE LAMBDA FUNCTION ===
echo "🚀 Creating Lambda function..."
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ROLE_ARN="arn:aws:iam::$ACCOUNT_ID:role/$ROLE_NAME"

# Try create-function, fallback to update
if aws lambda get-function --function-name $FUNCTION_NAME --region $REGION > /dev/null 2>&1; then
  echo "🔁 Function already exists. Updating code..."
  aws lambda update-function-code \
    --function-name $FUNCTION_NAME \
    --zip-file fileb://$ZIP_FILE \
    --region $REGION > /dev/null
else
  echo "➕ Creating function from scratch..."
  aws lambda create-function \
    --function-name $FUNCTION_NAME \
    --runtime python3.11 \
    --role $ROLE_ARN \
    --handler lambda_function.lambda_handler \
    --zip-file fileb://$ZIP_FILE \
    --region $REGION \
    --environment "Variables={OPENWEATHER_API_KEY=0fcf120f858a4b75af80f6ffe030e295,S3_BUCKET_NAME=$BUCKET_NAME,CITY=\"Tampa,US\",S3_KEY=$ZIP_KEY}" \
    > /dev/null
fi

# === STEP 6: CREATE EVENTBRIDGE RULE ===
echo "⏱️ Setting up EventBridge schedule..."
aws events put-rule \
  --name $SCHEDULE_RULE \
  --schedule-expression "rate(30 minutes)" \
  --region $REGION > /dev/null

# === STEP 7: GRANT PERMISSION TO EVENTBRIDGE ===
echo "🔗 Connecting EventBridge to Lambda..."
aws lambda add-permission \
  --function-name $FUNCTION_NAME \
  --statement-id eventbridge-invoke \
  --action 'lambda:InvokeFunction' \
  --principal events.amazonaws.com \
  --source-arn arn:aws:events:$REGION:$ACCOUNT_ID:rule/$SCHEDULE_RULE \
  --region $REGION \
  || echo "ℹ️ Permission may already exist, skipping."

# === STEP 8: CONNECT RULE TO LAMBDA ===
FUNCTION_ARN=$(aws lambda get-function \
  --function-name $FUNCTION_NAME \
  --region $REGION \
  --query 'Configuration.FunctionArn' \
  --output text)

aws events put-targets \
  --rule $SCHEDULE_RULE \
  --targets "Id"="1","Arn"="$FUNCTION_ARN" \
  --region $REGION > /dev/null

echo "✅ Lambda '$FUNCTION_NAME' deployed and scheduled every 30 minutes!"
echo "📂 Output goes to s3://$BUCKET_NAME/$ZIP_KEY"
