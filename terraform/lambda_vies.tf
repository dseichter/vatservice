resource "aws_iam_role" "vies" {
  name               = "vatservice_vies"
  assume_role_policy = data.aws_iam_policy_document.assume_role_lambda.json
}

data "archive_file" "vies" {
  type        = "zip"
  source_file = "${path.root}/../lambda/vies/lambda_function.py"
  output_path = "${path.root}/../lambda/vies/lambda_function.zip"
}

resource "aws_lambda_function" "vies" {

  function_name = "vatservice-vies"

  layers                         = []
  memory_size                    = 128
  reserved_concurrent_executions = -1
  timeout                        = 3

  filename         = data.archive_file.vies.output_path
  source_code_hash = data.archive_file.vies.output_base64sha256

  role    = aws_iam_role.vies.arn
  handler = "lambda_function.lambda_handler"

  runtime = "python3.12"

  environment {
    variables = {
      DYNAMODB       = aws_dynamodb_table.vatservice.id
      DYNAMODB_CODES = aws_dynamodb_table.vatservice_responsecodes["vies"].id
      URL            = "https://ec.europa.eu/taxation_customs/vies/services/checkVatService"
      TYPE           = "vies"
    }
  }

}

resource "aws_lambda_permission" "vies" {
  statement_id  = "AllowAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.vies.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.vat_service.execution_arn}/*"
}

resource "aws_lambda_permission" "vies_sfn" {
  statement_id  = "AllowStepFunctionInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.vies.function_name
  principal     = "states.amazonaws.com"
  source_arn    = aws_sfn_state_machine.validation.arn
}

resource "aws_iam_role_policy_attachment" "vies" {
  policy_arn = aws_iam_policy.vies.arn
  role       = aws_iam_role.vies.id
}

resource "aws_iam_policy" "vies" {
  name = "vatservice-${aws_lambda_function.vies.function_name}"
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
          Resource = "${aws_cloudwatch_log_group.validate-vies.arn}:*"
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
            aws_dynamodb_table.vatservice_responsecodes["vies"].arn
          ]
          Sid = "VisualEditor1"
        },
      ]
      Version = "2012-10-17"
    }
  )
}