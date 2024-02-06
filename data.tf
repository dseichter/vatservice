data "aws_route53_zone" "erpware_co" {
  name = "erpware.co."
}

data "aws_caller_identity" "current" {
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}