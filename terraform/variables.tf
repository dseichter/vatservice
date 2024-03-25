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