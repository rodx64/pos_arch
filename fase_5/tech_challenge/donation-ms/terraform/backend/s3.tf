resource "aws_s3_bucket" "state" {
  bucket        = "solidary-iac-state"
  force_destroy = true

  tags = {
    Purpose = "Terraform Backend"
    Project = "solidary-tech"
    CostCenter = "solidary-core"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state_encryption" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "state_ver" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}
