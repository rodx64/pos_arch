resource "aws_s3_bucket" "velero_backups" {
  provider      = aws.dr
  bucket        = "solidary-tech-velero-backups-${var.environment}"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "velero_versioning" {
  provider = aws.dr
  bucket   = aws_s3_bucket.velero_backups.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "velero_retention" {
  provider = aws.dr
  bucket   = aws_s3_bucket.velero_backups.id
  rule {
    id     = "expire-old-backups"
    status = "Enabled"
    expiration {
      days = 90
    }
  }
}

data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

output "velero_role_arn" {
  value       = data.aws_iam_role.lab_role.arn
  description = "ARN da Role do AWS Lab a ser utilizada pelo Velero"
}
