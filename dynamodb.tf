resource "aws_dynamodb_table" "ew_validation_service" {
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "vat"
  name           = "ew_validation_service"
  read_capacity  = 0
  stream_enabled = false
  write_capacity = 0

  attribute {
    name = "vat"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  timeouts {}

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      read_capacity,
      write_capacity
    ]
  }
}