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
        Is_GB = {
          Choices = [
            {
              Next          = "HMRC"
              StringMatches = "GB*"
              Variable      = "$.foreignvat"
            },
          ]
          Default = "Parallel"
          Type    = "Choice"
        }
        Parallel = {
          Branches = [
            {
              StartAt = "VIES"
              States = {
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
            },
            {
              StartAt = "BZST"
              States = {
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
              }
            },
          ]
          End  = true
          Type = "Parallel"
        }
      }
    }
  )
  publish  = false
  role_arn = "arn:aws:iam::547989225539:role/service-role/StepFunctions-MyStateMachine-r4vhmkgsv-role-kqp3ntjb5"
  type     = "EXPRESS"

  # logging_configuration {
  #   log_destination        = "${aws_cloudwatch_log_group.step-functions.arn}:*"
  #   include_execution_data = true
  #   level                  = "ERROR"
  # }

  tracing_configuration {
    enabled = false
  }

}