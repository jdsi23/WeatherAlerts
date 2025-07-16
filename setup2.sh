#!/bin/bash

# === CONFIG ===
FUNCTION_NAME="weather_fetcher"
ZIP_FILE="lambda_package.zip"
ROLE_NAME="weather_lambda_role"
BUCKET_NAME="sadasdasdasd13"
REGION="us-east-1"
SCHEDULE_RULE="weather_30min_rule"
ZIP_KEY="weather_data.csv"

# === STEP 1: ZIP THE LAMBDA CODE ===
echo "📦 Zipping code..."
zip -j $ZIP_FILE lambda_function.py

# === STEP 2: CREATE IAM ROLE ===
echo "🔐 Creating IAM role..."
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

# === STEP 3: ATTACH BASIC POLICIES ===
echo "🔒 Attaching policies..."
aws iam attach-role-policy \
  --role-name $ROLE_NAME \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

aws iam attach-role-policy \
  --role-name $ROLE_NAME \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess

# === STEP 4: WAIT FOR IAM ROLE TO BE USABLE ===
echo "⏳ Waiting for role to be ready..."
sleep 15

# === STEP 5: CREATE THE LAMBDA FUNCTION ===
echo "🚀 Creating Lambda function..."
aws lambda create-function \
  --function-name $FUNCTION_NAME \
  --runtime python3.11 \
  --role arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/$ROLE_NAME \
  --handler lambda_function.lambda_handler \
  --zip-file fileb://$ZIP_FILE \
  --region $REGION \
  --environment Variables="{OPENWEATHER_API_KEY=0fcf120f858a4b75af80f6ffe030e295,S3_BUCKET_NAME=sadasdasdasd13,CITY=\"Tampa,US\",S3_KEY=weather_data.csv}"
  > /dev/null

# === STEP 6: CREATE CLOUDWATCH SCHEDULE RULE ===
echo "⏱️ Creating 30-min EventBridge rule..."
aws events put-rule \
  --name $SCHEDULE_RULE \
  --schedule-expression "rate(30 minutes)" \
  --region $REGION

# === STEP 7: GRANT EVENTBRIDGE PERMISSION TO INVOKE LAMBDA ===
aws lambda add-permission \
  --function-name $FUNCTION_NAME \
  --statement-id eventbridge-invoke \
  --action 'lambda:InvokeFunction' \
  --principal events.amazonaws.com \
  --source-arn arn:aws:events:$REGION:$(aws sts get-caller-identity --query Account --output text):rule/$SCHEDULE_RULE \
  --region $REGION \
  > /dev/null

# === STEP 8: LINK RULE TO FUNCTION ===
aws events put-targets \
  --rule $SCHEDULE_RULE \
  --targets "Id"="1","Arn"="$(aws lambda get-function --function-name $FUNCTION_NAME --region $REGION --query 'Configuration.FunctionArn' --output text)" \
  --region $REGION

echo "✅ Setup complete. Lambda '$FUNCTION_NAME' runs every 30 minutes and writes to s3://$BUCKET_NAME/$ZIP_KEY"
