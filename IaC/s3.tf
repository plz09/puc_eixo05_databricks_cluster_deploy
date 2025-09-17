resource "aws_s3_bucket" "lake" {
  bucket        = var.s3_bucket
  force_destroy = false
  tags = {
    project = "databricks-ml"
    layer   = "lake"
  }
}

# bloqueio de acesso publico
resource "aws_s3_bucket_public_access_block" "lake" {
  bucket                  = aws_s3_bucket.lake.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# versionamento
resource "aws_s3_bucket_versioning" "lake" {
  bucket = aws_s3_bucket.lake.id
  versioning_configuration { status = "Enabled" }
}

# criptografia no lado do servidor
resource "aws_s3_bucket_server_side_encryption_configuration" "lake" {
  bucket = aws_s3_bucket.lake.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}


output "bronze_uri" {
  value = "s3://${aws_s3_bucket.lake.bucket}/bronze/"
}
