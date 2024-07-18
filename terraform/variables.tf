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

variable "route53zone" {
  description = "The Route53 zone for the API Gateway"
  type        = string
}

variable "domainname" {
  description = "The domain name for the API Gateway"
  type        = string
}

variable "region" {
  description = "The region for the resources"
  type        = string
}

variable "aws_kms_key" {
  description = "CMK KMS key to be used for encryption. If not provided, we will create one."
  type        = string
  default     = ""
}

variable "retention_in_days" {
  description = "The number of days to retain the logs"
  type        = number
  default     = 14

}