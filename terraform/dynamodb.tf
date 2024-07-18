# Copyright (c) 2024 Daniel Seichter
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.

resource "aws_dynamodb_table" "vatservice" {
  billing_mode                = "PAY_PER_REQUEST"
  hash_key                    = "vat"
  range_key                   = "date"
  name                        = "vatservice"
  read_capacity               = 0
  stream_enabled              = false
  write_capacity              = 0
  deletion_protection_enabled = true

  server_side_encryption {
    enabled     = true ? local.kms_id != "" : false
    kms_key_arn = local.kms_id
  }

  attribute {
    name = "vat"
    type = "S"
  }

  attribute {
    name = "date"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  timeouts {}

  lifecycle {
    #prevent_destroy = true
    ignore_changes = [
      read_capacity,
      write_capacity
    ]
  }
}

resource "aws_dynamodb_table" "vatservice_responsecodes" {
  for_each                    = toset(local.type)
  billing_mode                = "PAY_PER_REQUEST"
  hash_key                    = "status"
  name                        = "vatservice_responsecodes_${each.key}"
  read_capacity               = 0
  stream_enabled              = false
  write_capacity              = 0
  deletion_protection_enabled = true

  server_side_encryption {
    enabled     = true ? local.kms_id != "" : false
    kms_key_arn = local.kms_id
  }

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
  bzst = jsondecode(file("${path.root}/../data/responsecodes_bzst.json"))
  vies = jsondecode(file("${path.root}/../data/responsecodes_vies.json"))
  hmrc = jsondecode(file("${path.root}/../data/responsecodes_hmrc.json"))
}

resource "aws_dynamodb_table_item" "responsecode_bzst" {
  for_each   = { for k, v in local.bzst : k => v }
  table_name = aws_dynamodb_table.vatservice_responsecodes["bzst"].name
  hash_key   = aws_dynamodb_table.vatservice_responsecodes["bzst"].hash_key

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
  table_name = aws_dynamodb_table.vatservice_responsecodes["vies"].name
  hash_key   = aws_dynamodb_table.vatservice_responsecodes["vies"].hash_key

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
  table_name = aws_dynamodb_table.vatservice_responsecodes["hmrc"].name
  hash_key   = aws_dynamodb_table.vatservice_responsecodes["hmrc"].hash_key

  item = jsonencode(
    {
      "status" = { "S" : each.key },
      "de"     = { "S" : each.value.de },
      "en"     = { "S" : each.value.en }
    }
  )

}