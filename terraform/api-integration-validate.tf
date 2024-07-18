# Copyright (c) 2024 Daniel Seichter
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.

resource "aws_api_gateway_resource" "validate" {
  parent_id   = aws_api_gateway_rest_api.vat_service.root_resource_id
  path_part   = "validate"
  rest_api_id = aws_api_gateway_rest_api.vat_service.id
}

resource "aws_api_gateway_method" "validate_post" {
  authorization = "NONE" #NOSONAR
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
  uri                  = aws_lambda_function.validate.invoke_arn
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
