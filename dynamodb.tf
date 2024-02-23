resource "aws_dynamodb_table" "ew_validation_service" {
  billing_mode                = "PAY_PER_REQUEST"
  hash_key                    = "vat"
  name                        = "ew_validation_service"
  read_capacity               = 0
  stream_enabled              = false
  write_capacity              = 0
  deletion_protection_enabled = true

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

resource "aws_dynamodb_table" "ew_validation_responsecodes" {
  for_each                    = toset(local.type)
  billing_mode                = "PAY_PER_REQUEST"
  hash_key                    = "status"
  name                        = "ew_validation_service_responsecodes_${each.key}"
  read_capacity               = 0
  stream_enabled              = false
  write_capacity              = 0
  deletion_protection_enabled = true

  attribute {
    name = "status"
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

locals {
  type = ["vies", "bzst", "hmrc"]
  bzst = jsondecode(file("${path.root}/data/responsecodes_bzst.json"))
  vies = jsondecode(file("${path.root}/data/responsecodes_vies.json"))
  hmrc = jsondecode(file("${path.root}/data/responsecodes_hmrc.json"))
}

resource "aws_dynamodb_table_item" "responsecode_bzst" {
  for_each   = { for k, v in local.bzst : k => v }
  table_name = aws_dynamodb_table.ew_validation_responsecodes["bzst"].name
  hash_key   = aws_dynamodb_table.ew_validation_responsecodes["bzst"].hash_key

  item = jsonencode(
    {
      "status" = { "S" : each.key },
      "de"     = { "S" : each.value.de },
      "en"     = { "S" : each.value.en }
    }
  )

}

resource "aws_dynamodb_table_item" "responsecode_vies" {
  for_each   = { for k, v in local.vies : k => v }
  table_name = aws_dynamodb_table.ew_validation_responsecodes["vies"].name
  hash_key   = aws_dynamodb_table.ew_validation_responsecodes["vies"].hash_key

  item = jsonencode(
    {
      "status" = { "S" : each.key },
      "de"     = { "S" : each.value.de },
      "en"     = { "S" : each.value.en }
    }
  )

}

resource "aws_dynamodb_table_item" "responsecode_hmrc" {
  for_each   = { for k, v in local.hmrc : k => v }
  table_name = aws_dynamodb_table.ew_validation_responsecodes["hmrc"].name
  hash_key   = aws_dynamodb_table.ew_validation_responsecodes["hmrc"].hash_key

  item = jsonencode(
    {
      "status" = { "S" : each.key },
      "de"     = { "S" : each.value.de },
      "en"     = { "S" : each.value.en }
    }
  )

}