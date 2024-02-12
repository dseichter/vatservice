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
            FunctionName = "arn:aws:lambda:eu-central-1:547989225539:function:vat-validate-hmrc:$LATEST"
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
            FunctionName = "arn:aws:lambda:eu-central-1:547989225539:function:vat-validate-bzst:$LATEST"
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
            FunctionName = "arn:aws:lambda:eu-central-1:547989225539:function:vat-validate-vies:$LATEST"
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
  role_arn = "arn:aws:iam::547989225539:role/service-role/StepFunctions-MyStateMachine-r4vhmkgsv-role-kqp3ntjb5"
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
  name               = "StepFunctions-MyStateMachine-r4vhmkgsv-role-kqp3ntjb5"
  path               = "/service-role/"
  assume_role_policy = data.aws_iam_policy_document.assume_role_states.json
  # managed_policy_arns = [
  #   "arn:aws:iam::547989225539:policy/service-role/LambdaInvokeScopedAccessPolicy-cd2b2969-2fbe-42af-a31c-164b34dd80e8",
  #   "arn:aws:iam::547989225539:policy/service-role/XRayAccessPolicy-4dc30213-f118-41da-9813-12ef3c432da1"
  # ]
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
  name        = "LambdaInvokeScopedAccessPolicy-cd2b2969-2fbe-42af-a31c-164b34dd80e8"
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
            "arn:aws:lambda:eu-central-1:547989225539:function:vat-validate-vies:*",
            "arn:aws:lambda:eu-central-1:547989225539:function:vat-validate-bzst:*",
            "arn:aws:lambda:eu-central-1:547989225539:function:vat-validate-hmrc:*",
          ]
        },
        {
          Action = [
            "lambda:InvokeFunction",
          ]
          Effect = "Allow"
          Resource = [
            "arn:aws:lambda:eu-central-1:547989225539:function:vat-validate-vies",
            "arn:aws:lambda:eu-central-1:547989225539:function:vat-validate-bzst",
            "arn:aws:lambda:eu-central-1:547989225539:function:vat-validate-hmrc",
          ]
        },
      ]
      Version = "2012-10-17"
    }
  )
}
resource "aws_iam_policy" "sf_xray" {
  name        = "XRayAccessPolicy-4dc30213-f118-41da-9813-12ef3c432da1"
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