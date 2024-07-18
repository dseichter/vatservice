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

# prevent cycles, so we will use locals here
locals {
  # generate arn of the lambda function
  function_bzst_arn     = "arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:vatservice-bzst"
  function_vies_arn     = "arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:vatservice-vies"
  function_hmrc_arn     = "arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:vatservice-hmrc"

  create_kms = var.aws_kms_key == "" ? true : false
  kms_id     = local.create_kms ? aws_kms_key.vatservice[0].arn : var.aws_kms_key

}