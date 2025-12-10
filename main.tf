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

resource "aws_lambda_function" "api_handler" {
  function_name = "m346-api-handler"
  role = "arn:aws:iam::654654587245:role/LabRole"
  runtime = "python3.9"
  handler = "lambda_function.lambda_handler"

  filename = ""
  source_code_hash = filebase65sha256("")
}
resource "aws_apigatewayv2_api" "http_api" {
  name = "m346-http-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id = aws_apigatewayv2_api.http_api.id
  integration_type = "AWS_PROXY"
  integration_uri = aws_lambda_function.api_handler.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "default_route" {
  api_id = aws_apigatewayv2_api.http_api.id
  route_key = "GET /"
  target = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
  
}

resource "aws_lambda_permission" "allow_apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

output "api_url" {
  value = aws_apigatewayv2_api.http_api.api_endpoint
}

resource "aws_dynamodb_table" "notes" {
  name         = "Notes"
  billing_mode = "PAY_PER_REQUEST"

  # Primary Key
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "created_time"
    type = "S"
  }

  attribute {
    name = "text"
    type = "S"
  }

  attribute {
    name = "title"
    type = "S"
  }

  tags = {
    Project = "M346"
  }
}


resource "aws_lambda_function" "api_handler" {
  function_name = "m346-api-handler"
  role          = "arn:aws:iam::<ACCOUNT-ID>:role/LabRole"
  runtime       = "python3.9"
  handler       = "lambda_function.lambda_handler"

  filename         = "lambda_function.zip"
  source_code_hash = filebase64sha256("lambda_function.zip")

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.images.name
    }
  }
}
