resource "aws_iam_role" "bzst" {
  name               = "vat_validate_bzst"
  assume_role_policy = data.aws_iam_policy_document.assume_role_lambda.json
}

data "archive_file" "bzst" {
  type        = "zip"
  source_file = "lambda/bzst/lambda_function.py"
  output_path = "lambda/bzst/lambda_function.zip"
}

resource "aws_lambda_function" "bzst" {

  function_name = "vat-validate-bzst"

  layers                         = []
  memory_size                    = 128
  reserved_concurrent_executions = -1
  timeout                        = 10

  filename         = data.archive_file.bzst.output_path
  source_code_hash = data.archive_file.bzst.output_base64sha256

  role    = aws_iam_role.bzst.arn
  handler = "lambda_function.lambda_handler"

  runtime = "python3.12"

  environment {
    variables = {
      DYNAMODB = aws_dynamodb_table.ew_validation_service.id
    }
  }

}

resource "aws_lambda_permission" "bzst" {
  statement_id  = "AllowEWAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.bzst.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.vat_service.execution_arn}/*"
}

resource "aws_iam_role_policy_attachment" "bzst" {
  policy_arn = aws_iam_policy.bzst.arn
  role       = aws_iam_role.bzst.id
}

resource "aws_iam_policy" "bzst" {
  name = "ew_policy-${aws_lambda_function.bzst.function_name}"
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
          Resource = "${aws_cloudwatch_log_group.validate-bzst.arn}:*"
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