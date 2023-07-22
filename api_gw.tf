resource "aws_api_gateway_rest_api" "jigsaw_api" {
  name        = "jigsaw-api"
  description = "API Gateway for the jigsaw Lambda function"
  # pass client ip to the backend
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  
}

resource "aws_api_gateway_resource" "jigsaw_resource" {
  rest_api_id = aws_api_gateway_rest_api.jigsaw_api.id
  parent_id   = aws_api_gateway_rest_api.jigsaw_api.root_resource_id
  path_part   = "jigsaw"
}

resource "aws_api_gateway_method" "jigsaw_method" {
  rest_api_id   = aws_api_gateway_rest_api.jigsaw_api.id
  resource_id   = aws_api_gateway_resource.jigsaw_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "jigsaw_integration" {
  rest_api_id = aws_api_gateway_rest_api.jigsaw_api.id
  resource_id = aws_api_gateway_resource.jigsaw_resource.id
  http_method = aws_api_gateway_method.jigsaw_method.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.jigsaw.invoke_arn
}

resource "aws_api_gateway_resource" "jigsaw_resource2" {
  rest_api_id = aws_api_gateway_rest_api.jigsaw_api.id
  parent_id   = aws_api_gateway_rest_api.jigsaw_api.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "jigsaw_method2" {
  rest_api_id   = aws_api_gateway_rest_api.jigsaw_api.id
  resource_id   = aws_api_gateway_resource.jigsaw_resource2.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "jigsaw_integration2" {
  rest_api_id = aws_api_gateway_rest_api.jigsaw_api.id
  resource_id = aws_api_gateway_resource.jigsaw_resource2.id
  http_method = aws_api_gateway_method.jigsaw_method2.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.jigsaw.invoke_arn
}


resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.jigsaw.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.jigsaw_api.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "jigsaw_deployment" {
  depends_on  = [aws_api_gateway_integration.jigsaw_integration2]
  rest_api_id = aws_api_gateway_rest_api.jigsaw_api.id
  stage_name  = "prod"
}

output "api_url" {
  value = "${aws_api_gateway_deployment.jigsaw_deployment.invoke_url}"
}