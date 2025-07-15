provider "aws" {
  region = "us-east-1"  # Adjust as needed
}

variable "weather_api_key" {
  description = "API key for the weather service"
  type        = string
  sensitive   = true
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "weather_raw_data" {
  bucket = "tnjweathers-${random_id.bucket_suffix.hex}"

  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket_acl" "weather_raw_data_acl" {
  bucket = aws_s3_bucket.weather_raw_data.id
  acl    = "private"
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "TnJ-lambda-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name = "TnJ-lambda-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Effect   = "Allow"
        Resource = [
          aws_s3_bucket.weather_raw_data.arn,
          "${aws_s3_bucket.weather_raw_data.arn}/*"
        ]
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_attach_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_lambda_function" "weather_fetcher" {
  function_name = "smartinsights-weather-fetcher"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"

  filename         = "deployment_package.zip"
  source_code_hash = filebase64sha256("deployment_package.zip")

  environment {
    variables = {
      WEATHER_API_KEY = var.weather_api_key
      S3_BUCKET_NAME  = aws_s3_bucket.weather_raw_data.bucket
    }
  }

  timeout = 10  # Increased timeout to 10 seconds for external API calls
}
