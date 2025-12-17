terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# DynamoDB Table
resource "aws_dynamodb_table" "notes" {
  name         = "Notes"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"
  
  attribute {
    name = "id"
    type = "S"
  }
  
  tags = {
    Project = "M346"
  }
}

# Lambda ZIP
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "lambda_function.py"
  output_path = "lambda_function.zip"
}

# Lambda Function
resource "aws_lambda_function" "api_handler" {
  function_name    = "m346-api-handler"
  role            = "arn:aws:iam::654654587245:role/LabRole"
  runtime         = "python3.9"
  handler         = "lambda_function.lambda_handler"
  filename        = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  
  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.notes.name
    }
  }
}

# API Gateway HTTP API
resource "aws_apigatewayv2_api" "http_api" {
  name          = "m346-http-api"
  protocol_type = "HTTP"
}

# Lambda Integration
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id             = aws_apigatewayv2_api.http_api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.api_handler.invoke_arn
  payload_format_version = "2.0"
}

# GET /note Route
resource "aws_apigatewayv2_route" "get_notes" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /note"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# POST /note Route
resource "aws_apigatewayv2_route" "post_note" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /note"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Stage (deployed API)
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
}

# Lambda Permission
resource "aws_lambda_permission" "allow_apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

# Output
output "api_url" {
  value = aws_apigatewayv2_api.http_api.api_endpoint
}