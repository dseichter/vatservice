resource "aws_cloudwatch_log_group" "validate" {
  name              = "/aws/lambda/${aws_lambda_function.lambda_validate.function_name}"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "validate-bzst" {
  name              = "/aws/lambda/${aws_lambda_function.bzst.function_name}"
  retention_in_days = 14
}


resource "aws_cloudwatch_log_group" "validate-vies" {
  name              = "/aws/lambda/${aws_lambda_function.vies.function_name}"
  retention_in_days = 14
}


resource "aws_cloudwatch_log_group" "validate-hmrc" {
  name              = "/aws/lambda/${aws_lambda_function.hmrc.function_name}"
  retention_in_days = 14
}
