provider "aws" {
  region = "eu-north-1"
}

resource "aws_dynamodb_table" "users_table" {
  name         = "UsersTableGreeterTf"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"

  attribute {
    name = "userId"
    type = "S"
  }
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/handler.py"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_iam_role" "lambda_role" {
  name = "terraform-greeter-lambda-role"

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

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "greeter" {
  function_name    = "terraform-greeter"
  role             = aws_iam_role.lambda_role.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.12"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.users_table.name
    }
  }
}

resource "aws_iam_role_policy" "lambda_dynamodb" {
  name = "terraform-greeter-dynamodb-access"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Action = [
        "dynamodb:GetItem",
        "dynamodb:PutItem"
      ]

      Resource = aws_dynamodb_table.users_table.arn
    }]
  })
}

# API Gateway HTTP API
resource "aws_apigatewayv2_api" "greeter_api" {
  name          = "terraform-greeter-api"
  protocol_type = "HTTP"
}

# Connect API Gateway to Lambda
resource "aws_apigatewayv2_integration" "greeter_integration" {
  api_id                 = aws_apigatewayv2_api.greeter_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.greeter.invoke_arn
  payload_format_version = "2.0"
}

# Define the POST /users endpoint
resource "aws_apigatewayv2_route" "users_route" {
  api_id    = aws_apigatewayv2_api.greeter_api.id
  route_key = "POST /users"
  target    = "integrations/${aws_apigatewayv2_integration.greeter_integration.id}"
}

# Automatically deploy API changes
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.greeter_api.id
  name        = "$default"
  auto_deploy = true
}

# Allow API Gateway to invoke Lambda
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.greeter.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.greeter_api.execution_arn}/*/POST/users"
}

# Display the API URL after deployment
output "api_url" {
  value = "${aws_apigatewayv2_api.greeter_api.api_endpoint}/users"
}

