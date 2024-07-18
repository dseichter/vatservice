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

resource "aws_kms_key" "vatservice" {
  count                   = local.create_kms ? 1 : 0
  description             = "VATService KMS Key"
  deletion_window_in_days = 10
  enable_key_rotation     = true

}

resource "aws_kms_alias" "vatservice" {
  count         = local.create_kms ? 1 : 0
  name          = "alias/vatservice"
  target_key_id = aws_kms_key.vatservice[count.index].id
}

resource "aws_kms_key_policy" "vatservice" {
  count  = local.create_kms ? 1 : 0
  key_id = aws_kms_key.vatservice[count.index].id
  policy = jsonencode({
    Id = "VATService"
    Statement = [
      {
        Action = "kms:*"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }

        Resource = "*"
        Sid      = "VATServiceEncryption"
      },
    ]
    Version = "2012-10-17"
  })
}