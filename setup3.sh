#!/bin/bash

# === CONFIGURATION ===
FUNCTION_NAME="weather_fetcher"
REGION="us-east-1"
BUILD_DIR="lambda_build"
ZIP_FILE="lambda_package.zip"

echo "📦 Cleaning old build artifacts..."
rm -rf $BUILD_DIR $ZIP_FILE

# === STEP 1: Create build folder and install dependencies ===
echo "📂 Creating build folder..."
mkdir -p $BUILD_DIR

echo "📥 Installing dependencies (requests)..."
pip install requests -t $BUILD_DIR

# === STEP 2: Copy source code ===
echo "📄 Copying source files..."
cp lambda_function.py $BUILD_DIR/
cp upload_to_s3.py $BUILD_DIR/

# === STEP 3: Zip everything ===
echo "🗜️ Zipping contents..."
cd $BUILD_DIR
zip -r ../$ZIP_FILE . > /dev/null
cd ..

# === STEP 4: Update Lambda Function ===
echo "🚀 Updating Lambda function '$FUNCTION_NAME'..."
aws lambda update-function-code \
  --function-name $FUNCTION_NAME \
  --zip-file fileb://$ZIP_FILE \
  --region $REGION

echo "✅ Done! Lambda function updated with dependencies."
