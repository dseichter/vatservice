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
