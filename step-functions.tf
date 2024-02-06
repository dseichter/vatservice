resource "aws_sfn_state_machine" "validation" {

  name = "MyStateMachine-r4vhmkgsv"

  definition = jsonencode(
    {
      Comment = "A description of my state machine"
      StartAt = "Is_GB"
      States = {
        HRMC = {
          End        = true
          OutputPath = "$.Payload"
          Parameters = {
            FunctionName = "arn:aws:lambda:eu-central-1:547989225539:function:vat-validate-hrmc:$LATEST"
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
              Next          = "HRMC"
              StringMatches = "GB*"
              Variable      = "$.vat"
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
  type     = "STANDARD"

  logging_configuration {
    include_execution_data = false
    level                  = "OFF"
  }

  tracing_configuration {
    enabled = false
  }

}