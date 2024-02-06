resource "aws_iam_role" "hrmc" {
  name               = "vat_validate_hrmc"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "archive_file" "hrmc" {
  type        = "zip"
  source_file = "lambda/hrmc/lambda_function.py"
  output_path = "lambda/hrmc/lambda_function.zip"
}

resource "aws_lambda_function" "hrmc" {

  function_name = "vat-validate-hrmc"

  layers                         = []
  memory_size                    = 128
  reserved_concurrent_executions = -1
  timeout                        = 10

  filename         = data.archive_file.hrmc.output_path
  source_code_hash = data.archive_file.hrmc.output_base64sha256

  role    = aws_iam_role.hrmc.arn
  handler = "lambda_function.lambda_handler"

  runtime = "python3.12"

  environment {
    variables = {
      DYNAMODB = aws_dynamodb_table.ew_validation_service.id
    }
  }

}

resource "aws_lambda_permission" "hrmc" {
  statement_id  = "AllowEWAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hrmc.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.vat_service.execution_arn}/*"
}

resource "aws_iam_role_policy_attachment" "hrmc" {
  policy_arn = aws_iam_policy.hrmc.arn
  role       = aws_iam_role.hrmc.id
}

resource "aws_iam_policy" "hrmc" {
  name = "ew_policy-${aws_lambda_function.hrmc.function_name}"
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
          Resource = "${aws_cloudwatch_log_group.validate-hrmc.arn}:*"
          Sid      = "VisualEditor0"
        },
        {
          Action = [
            "dynamodb:BatchGetItem",
            "dynamodb:BatchWriteItem",
            "dynamodb:PutItem",
            "dynamodb:GetItem",
            "dynamodb:Scan",
            "dynamodb:Query",
            "dynamodb:UpdateItem",
          ]
          Effect = "Allow"
          Resource = [
            aws_dynamodb_table.ew_validation_service.arn
          ]
          Sid = "VisualEditor1"
        },
      ]
      Version = "2012-10-17"
    }
  )
}