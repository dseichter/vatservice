resource "aws_iam_role" "vat_validate" {
  name               = "vat_validate"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "archive_file" "lambda_validate" {
  type        = "zip"
  source_file = "lambda/validate/lambda_function.py"
  output_path = "lambda/validate/lambda_function.zip"
}

resource "aws_lambda_function" "lambda_validate" {

  function_name = "vat-validate"

  layers                         = []
  memory_size                    = 128
  reserved_concurrent_executions = -1
  timeout                        = 10


  filename         = data.archive_file.lambda_validate.output_path
  source_code_hash = data.archive_file.lambda_validate.output_base64sha256

  role    = aws_iam_role.vat_validate.arn
  handler = "lambda_function.lambda_handler"

  runtime = "python3.12"

  environment {
    variables = {
      STEPFUNCTION = aws_sfn_state_machine.validation.arn
    }
  }

}

resource "aws_lambda_permission" "lambda_vat_service" {
  statement_id  = "AllowEWAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_validate.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.vat_service.execution_arn}/*"
}

resource "aws_iam_role_policy_attachment" "role_policy_ew_idvalidation_licenceinfo" {
  policy_arn = aws_iam_policy.iam_policy_vat_service.arn
  role       = aws_iam_role.vat_validate.id
}

resource "aws_iam_policy" "iam_policy_vat_service" {
  name = "ew_policy-${aws_lambda_function.lambda_validate.function_name}"
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
            "states:StartExecution"
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