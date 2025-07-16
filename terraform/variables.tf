variable "region" {
  default = "us-east-1"
}

variable "bucket_name" {
  description = "S3 bucket name (must be globally unique)"
  default     = "weatheralerts-data-bucket-unique-12345" # Change this to your unique bucket name
}

variable "lambda_function_name" {
  default = "weather-data-refresh-lambda"
}

variable "ecs_cluster_name" {
  default = "weatheralerts-ecs-cluster"
}

variable "ecs_service_name" {
  default = "weatheralerts-ecs-service"
}

variable "ecs_task_cpu" {
  default = 256
}

variable "ecs_task_memory" {
  default = 512
}

variable "container_image" {
  description = "Container image URI"
  default     = "yourdockerhubuser/weatheralerts:latest"
}

variable "lambda_schedule_expression" {
  default = "rate(15 minutes)"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  default = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "weather_api_key" {
  description = "API key for the weather service"
  type        = string
  sensitive   = true
}
