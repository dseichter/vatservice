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

resource "aws_iam_role" "validate" {
  name               = "vatservice_validate"
  assume_role_policy = data.aws_iam_policy_document.assume_role_lambda.json
}

data "archive_file" "validate" {
  type        = "zip"
  source_file = "${path.root}/../lambda/validate/lambda_function.py"
  output_path = "${path.root}/../lambda/validate/lambda_function.zip"
}

resource "aws_lambda_function" "validate" {

  function_name = "vatservice-validate"

  layers                         = []
  memory_size                    = 128
  reserved_concurrent_executions = -1
  timeout                        = 10

  filename         = data.archive_file.validate.output_path
  source_code_hash = data.archive_file.validate.output_base64sha256

  role    = aws_iam_role.validate.arn
  handler = "lambda_function.lambda_handler"

  runtime = "python3.12"

  environment {
    variables = {
      STEPFUNCTION = aws_sfn_state_machine.validation.arn
    }
  }

}

resource "aws_lambda_permission" "validate" {
  statement_id  = "AllowAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.validate.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.vat_service.execution_arn}/*"
}

resource "aws_iam_role_policy_attachment" "validate" {
  policy_arn = aws_iam_policy.validate.arn
  role       = aws_iam_role.validate.id
}

resource "aws_iam_policy" "validate" {
  name = "vatservice-${aws_lambda_function.validate.function_name}"
  path = "/service-role/"
  policy = jsonencode(
    {
      Statement = [
        {
          Action = [
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ]
          Effect   = "Allow"
          Resource = "${aws_cloudwatch_log_group.validate.arn}:*"
          Sid      = "Cloudwatch"
        },
        {
          Action = [
            "states:StartSyncExecution"
          ]
          Effect = "Allow"
          Resource = [
            aws_sfn_state_machine.validation.arn
          ]
          Sid = "StepFunction"

        }
      ]
      Version = "2012-10-17"
    }
  )
}