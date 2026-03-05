resource "aws_s3_bucket" "state" {
  bucket        = "${var.project_name}-${var.env}-app"
  force_destroy = true

  tags = { 
    Name = "${var.project_name}-${var.env}-app" 
    Project = "${var.project_name}"
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
