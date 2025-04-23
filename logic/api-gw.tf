# This file contains the API Gateway configuration for the web app.
data "aws_caller_identity" "current" {}

resource "aws_api_gateway_rest_api" "default" {
    name        = "web-app-UserRequestAPI"
    description = "API for web app user requests"
    endpoint_configuration {
        types = ["REGIONAL"]
    }

}

resource "aws_api_gateway_stage" "default" {
  rest_api_id = aws_api_gateway_rest_api.default.id
  deployment_id = aws_api_gateway_deployment.default.id
  stage_name  = "prod"
  description = "Production stage for web app API"
  depends_on = [aws_api_gateway_rest_api.default]
}

resource "aws_api_gateway_deployment" "default" {
  rest_api_id = aws_api_gateway_rest_api.default.id
  depends_on = [
    aws_api_gateway_rest_api.default,
    aws_api_gateway_integration.default
  ]
}

resource "aws_api_gateway_resource" "default" {
  rest_api_id = aws_api_gateway_rest_api.default.id
  parent_id   = aws_api_gateway_rest_api.default.root_resource_id
  path_part   = "users"
  depends_on = [aws_api_gateway_rest_api.default]
}

resource "aws_api_gateway_method" "default" {
  rest_api_id   = aws_api_gateway_rest_api.default.id
  resource_id   = aws_api_gateway_resource.default.id
  http_method   = "GET"
  authorization = "NONE"
  depends_on    = [aws_api_gateway_resource.default]
}

resource "aws_api_gateway_method_response" "default" {
  rest_api_id = aws_api_gateway_rest_api.default.id
  resource_id = aws_api_gateway_resource.default.id
  http_method = aws_api_gateway_method.default.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_integration" "default" {
  rest_api_id             = aws_api_gateway_rest_api.default.id
  resource_id             = aws_api_gateway_resource.default.id
  http_method             = aws_api_gateway_method.default.http_method
  integration_http_method = "GET"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_function.invoke_arn
  depends_on              = [aws_api_gateway_method_response.default
    , aws_lambda_function.lambda_function
    , aws_api_gateway_method.default
  ]
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:eu-west-1:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.default.id}/*/${aws_api_gateway_method.default.http_method}${aws_api_gateway_resource.default.path}"
  depends_on = [aws_lambda_function.lambda_function
    , aws_api_gateway_rest_api.default
    , aws_api_gateway_method.default
    , aws_api_gateway_resource.default
    ]
}

resource "aws_api_gateway_integration_response" "default" {
  rest_api_id             = aws_api_gateway_rest_api.default.id
  resource_id             = aws_api_gateway_resource.default.id
  http_method             = aws_api_gateway_method.default.http_method
  status_code             = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
}