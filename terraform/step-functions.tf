resource "aws_sfn_state_machine" "validation" {

  name = "VAT-Validation"

  definition = jsonencode(
    {
      Comment = "A description of my state machine"
      StartAt = "Is_GB"
      States = {
        HMRC = {
          End        = true
          OutputPath = "$.Payload"
          Parameters = {
            FunctionName = "${aws_lambda_function.hmrc.arn}:$LATEST"
            "Payload.$"  = "$"
          }
          Resource = "arn:aws:states:::lambda:invoke"
          Retry = [
            {
              BackoffRate = 2
              ErrorEquals = [
                "Lambda.ServiceException",
                "Lambda.AWSLambdaException",
                "Lambda.SdkClientException",
                "Lambda.TooManyRequestsException",
              ]
              IntervalSeconds = 1
              MaxAttempts     = 3
            },
          ]
          Type = "Task"
        }
        BZST = {
          End        = true
          OutputPath = "$.Payload"
          Parameters = {
            FunctionName = "${aws_lambda_function.bzst.arn}:$LATEST"
            "Payload.$"  = "$"
          }
          Resource = "arn:aws:states:::lambda:invoke"
          Retry = [
            {
              BackoffRate = 2
              ErrorEquals = [
                "Lambda.ServiceException",
                "Lambda.AWSLambdaException",
                "Lambda.SdkClientException",
                "Lambda.TooManyRequestsException",
              ]
              IntervalSeconds = 1
              MaxAttempts     = 3
            },
          ]
          Type = "Task"
        }
        Choose_Type = {
          Choices = [
            {
              Next         = "BZST"
              StringEquals = "bzst"
              Variable     = "$.type"
            },
          ]
          Default = "VIES"
          Type    = "Choice"
        }
        Is_GB = {
          Choices = [
            {
              Next          = "HMRC"
              StringMatches = "GB*"
              Variable      = "$.foreignvat"
            },
          ]
          Default = "Choose_Type"
          Type    = "Choice"
        }
        VIES = {
          End        = true
          OutputPath = "$.Payload"
          Parameters = {
            FunctionName = "${aws_lambda_function.vies.arn}:$LATEST"
            "Payload.$"  = "$"
          }
          Resource = "arn:aws:states:::lambda:invoke"
          Retry = [
            {
              BackoffRate = 2
              ErrorEquals = [
                "Lambda.ServiceException",
                "Lambda.AWSLambdaException",
                "Lambda.SdkClientException",
                "Lambda.TooManyRequestsException",
              ]
              IntervalSeconds = 1
              MaxAttempts     = 3
            },
          ]
          Type = "Task"
        }
      }
    }
  )
  publish  = false
  role_arn = aws_iam_role.step_function.arn
  type     = "EXPRESS"

  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.step-functions.arn}:*"
    include_execution_data = true
    level                  = "ALL"
  }

  tracing_configuration {
    enabled = false
  }

}

resource "aws_iam_role" "step_function" {
  name               = "vatservice_stepfunction"
  path               = "/service-role/"
  assume_role_policy = data.aws_iam_policy_document.assume_role_states.json
  inline_policy {
    name = "Cloudwatch"
    policy = jsonencode(
      {
        Statement = [
          {
            Action = [
              "logs:CreateLogDelivery",
              "logs:CreateLogStream",
              "logs:GetLogDelivery",
              "logs:UpdateLogDelivery",
              "logs:DeleteLogDelivery",
              "logs:ListLogDeliveries",
              "logs:PutLogEvents",
              "logs:PutResourcePolicy",
              "logs:DescribeResourcePolicies",
              "logs:DescribeLogGroups",
            ]
            Effect   = "Allow"
            Resource = "*"
          },
        ]
        Version = "2012-10-17"
      }
    )
  }
}

resource "aws_iam_role_policy_attachment" "attach_xray" {
  role       = aws_iam_role.step_function.name
  policy_arn = aws_iam_policy.sf_xray.arn
}

resource "aws_iam_role_policy_attachment" "attach_lambda" {
  role       = aws_iam_role.step_function.name
  policy_arn = aws_iam_policy.sf_lambda.arn
}

resource "aws_iam_policy" "sf_lambda" {
  name        = "vatservice_stepfunction_lambda"
  description = "Allow AWS Step Functions to invoke Lambda functions on your behalf"
  path        = "/service-role/"
  policy = jsonencode(
    {
      Statement = [
        {
          Action = [
            "lambda:InvokeFunction",
          ]
          Effect = "Allow"
          Resource = [
            "${local.function_bzst_arn}:*",
            "${local.function_hmrc_arn}:*",
            "${local.function_vies_arn}:*",
          ]
        },
        {
          Action = [
            "lambda:InvokeFunction",
          ]
          Effect = "Allow"
          Resource = [
            local.function_bzst_arn,
            local.function_hmrc_arn,
            local.function_vies_arn
          ]
        },
      ]
      Version = "2012-10-17"
    }
  )
}
resource "aws_iam_policy" "sf_xray" {
  name        = "vatservice_stepfunction_xray"
  description = "Allow AWS Step Functions to call X-Ray daemon on your behalf"
  path        = "/service-role/"
  policy = jsonencode(
    {
      Statement = [
        {
          Action = [
            "xray:PutTraceSegments",
            "xray:PutTelemetryRecords",
            "xray:GetSamplingRules",
            "xray:GetSamplingTargets",
          ]
          Effect = "Allow"
          Resource = [
            "*",
          ]
        },
      ]
      Version = "2012-10-17"
    }
  )
}