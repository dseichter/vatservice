resource "aws_api_gateway_resource" "validate" {
  parent_id   = aws_api_gateway_rest_api.vat_service.root_resource_id
  path_part   = "validate"
  rest_api_id = aws_api_gateway_rest_api.vat_service.id
}

resource "aws_api_gateway_method" "validate_post" {
  authorization = "NONE"
  http_method   = "POST"
  resource_id   = aws_api_gateway_resource.validate.id
  rest_api_id   = aws_api_gateway_rest_api.vat_service.id
}

resource "aws_api_gateway_integration" "validate_post" {
  http_method = aws_api_gateway_method.validate_post.http_method
  resource_id = aws_api_gateway_resource.validate.id
  rest_api_id = aws_api_gateway_rest_api.vat_service.id

  integration_http_method = "POST"
  passthrough_behavior    = "WHEN_NO_MATCH"
  request_parameters      = {}
  request_templates       = {}

  timeout_milliseconds = 29000
  type                 = "AWS_PROXY"
  uri                  = aws_lambda_function.lambda_validate.invoke_arn
}

resource "aws_api_gateway_integration_response" "validate_post" {
  http_method = aws_api_gateway_method.validate_post.http_method
  resource_id = aws_api_gateway_resource.validate.id
  rest_api_id = aws_api_gateway_rest_api.vat_service.id
  status_code = "200"

  depends_on = [
    aws_api_gateway_integration.validate_post
  ]
}
