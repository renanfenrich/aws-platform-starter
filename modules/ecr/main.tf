locals {
  repository_name_input = var.repository_name_override == null ? "" : trimspace(var.repository_name_override)
  repository_name       = length(local.repository_name_input) > 0 ? var.repository_name_override : "${var.name_prefix}-${var.service_name}"
}

resource "aws_ecr_repository" "this" {
  name                 = local.repository_name
  image_tag_mutability = var.immutable_tags ? "IMMUTABLE" : "MUTABLE"

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = var.tags
}

resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images beyond ${var.lifecycle_keep_last} images"
        selection = {
          tagStatus   = "untagged"
          countType   = "imageCountMoreThan"
          countNumber = var.lifecycle_keep_last
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
