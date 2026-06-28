resource "aws_ecr_repository" "this" {
  for_each = toset(var.repositories)

  name                 = each.key
  image_tag_mutability = "MUTABLE"
  force_delete         = var.force_delete

  image_scanning_configuration {
    scan_on_push = true
  }

  lifecycle {
    ignore_changes = all
  }

  tags = {
    Name = each.key
  }
}

resource "aws_ecr_lifecycle_policy" "this" {
  for_each   = { for repo in var.repositories : repo => repo }
  repository = each.key

  depends_on = [aws_ecr_repository.this]

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images per service tag"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = length(var.tag_prefixes) > 0 ? var.tag_prefixes : var.repositories
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Remove untagged images after 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = { type = "expire" }
      }
    ]
  })

  lifecycle {
    ignore_changes = all
  }
}
