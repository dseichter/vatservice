resource "aws_iam_role" "hmrc" {
  name               = "vat_validate_hmrc"
  assume_role_policy = data.aws_iam_policy_document.assume_role_lambda.json
}

data "archive_file" "hmrc" {
  type        = "zip"
  source_file = "lambda/hmrc/lambda_function.py"
  output_path = "lambda/hmrc/lambda_function.zip"
}

resource "aws_lambda_function" "hmrc" {

  function_name = "vat-validate-hmrc"

  layers                         = []
  memory_size                    = 128
  reserved_concurrent_executions = -1
  timeout                        = 10

  filename         = data.archive_file.hmrc.output_path
  source_code_hash = data.archive_file.hmrc.output_base64sha256

  role    = aws_iam_role.hmrc.arn
  handler = "lambda_function.lambda_handler"

  runtime = "python3.12"

  environment {
    variables = {
      DYNAMODB = aws_dynamodb_table.ew_validation_service.id
      URL      = "https://api.service.hmrc.gov.uk/organisations/vat/check-vat-number/lookup/"
      TYPE     = "hmrc"
    }
  }

}

resource "aws_lambda_permission" "hmrc" {
  statement_id  = "AllowEWAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hmrc.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.vat_service.execution_arn}/*"
}

resource "aws_iam_role_policy_attachment" "hmrc" {
  policy_arn = aws_iam_policy.hmrc.arn
  role       = aws_iam_role.hmrc.id
}

resource "aws_iam_policy" "hmrc" {
  name = "ew_policy-${aws_lambda_function.hmrc.function_name}"
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
          Resource = "${aws_cloudwatch_log_group.validate-hmrc.arn}:*"
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