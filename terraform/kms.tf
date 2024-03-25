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