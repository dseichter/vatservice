resource "aws_cloudwatch_log_group" "validate" {
  name              = "/aws/lambda/${aws_lambda_function.validate.function_name}"
  retention_in_days = var.retention_in_days
  kms_key_id        = local.kms_id
}

resource "aws_cloudwatch_log_group" "validate-bzst" {
  name              = "/aws/lambda/${aws_lambda_function.bzst.function_name}"
  retention_in_days = var.retention_in_days
  kms_key_id        = local.kms_id
}

resource "aws_cloudwatch_log_group" "validate-vies" {
  name              = "/aws/lambda/${aws_lambda_function.vies.function_name}"
  retention_in_days = var.retention_in_days
  kms_key_id        = local.kms_id
}

resource "aws_cloudwatch_log_group" "validate-hmrc" {
  name              = "/aws/lambda/${aws_lambda_function.hmrc.function_name}"
  retention_in_days = var.retention_in_days
  kms_key_id        = local.kms_id
}

resource "aws_cloudwatch_log_group" "step-functions" {
  name              = "/aws/vendedlogs/states/VAT-Validation"
  retention_in_days = var.retention_in_days
  kms_key_id        = local.kms_id
}
