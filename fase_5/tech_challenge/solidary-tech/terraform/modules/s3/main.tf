# 1. CRIAÇÃO ÚNICA DO BUCKET
resource "aws_s3_bucket" "state" {
  bucket        = "${var.project_name}-${var.env}-app"
  force_destroy = true

  tags = {
    Name = "${var.project_name}-${var.env}-app"
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
    status = var.versioning_configuration
  }
}


resource "aws_s3_bucket_website_configuration" "app_website" {
  bucket = aws_s3_bucket.state.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "app_access" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "app_policy" {
  depends_on = [aws_s3_bucket_public_access_block.app_access]
  bucket     = aws_s3_bucket.state.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.state.arn}/*"
      },
    ]
  })
}
