# prevent cycles, so we will use locals here
locals {
  # generate arn of the lambda function
  function_validate_arn = "arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:vatservice-validate"
  function_bzst_arn     = "arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:vatservice-bzst"
  function_vies_arn     = "arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:vatservice-vies"
  function_hmrc_arn     = "arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:vatservice-hmrc"

  create_kms = var.aws_kms_key == "" ? true : false
  kms_id     = local.create_kms ? aws_kms_key.vatservice[0].arn : var.aws_kms_key

}