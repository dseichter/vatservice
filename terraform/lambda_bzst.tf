resource "aws_iam_role" "bzst" {
  name               = "vatservice_bzst"
  assume_role_policy = data.aws_iam_policy_document.assume_role_lambda.json
}

data "archive_file" "bzst" {
  type        = "zip"
  source_file = "${path.root}/../lambda/bzst/lambda_function.py"
  output_path = "${path.root}/../lambda/bzst/lambda_function.zip"
}

resource "aws_lambda_function" "bzst" {

  function_name = "vatservice-bzst"

  layers                         = []
  memory_size                    = 128
  reserved_concurrent_executions = -1
  timeout                        = 3

  filename         = data.archive_file.bzst.output_path
  source_code_hash = data.archive_file.bzst.output_base64sha256

  role    = aws_iam_role.bzst.arn
  handler = "lambda_function.lambda_handler"

  runtime = "python3.12"

  environment {
    variables = {
      DYNAMODB       = aws_dynamodb_table.vatservice.id
      DYNAMODB_CODES = aws_dynamodb_table.vatservice_responsecodes["bzst"].id
      URL            = "https://evatr.bff-online.de/evatrRPC"
      TYPE           = "bzst"
    }
  }

}

resource "aws_lambda_permission" "bzst" {
  statement_id  = "AllowAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.bzst.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.vat_service.execution_arn}/*"
}

resource "aws_lambda_permission" "bzst_sfn" {
  statement_id  = "AllowStepFunctionInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.bzst.function_name
  principal     = "states.amazonaws.com"
  source_arn    = aws_sfn_state_machine.validation.arn
}

resource "aws_iam_role_policy_attachment" "bzst" {
  policy_arn = aws_iam_policy.bzst.arn
  role       = aws_iam_role.bzst.id
}

resource "aws_iam_policy" "bzst" {
  name = "vatservice-${aws_lambda_function.bzst.function_name}"
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
            aws_dynamodb_table.vatservice.arn,
            aws_dynamodb_table.vatservice_responsecodes["bzst"].arn
          ]
          Sid = "VisualEditor1"
        },
      ]
      Version = "2012-10-17"
    }
  )
}