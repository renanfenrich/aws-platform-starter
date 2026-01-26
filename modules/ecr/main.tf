locals {
  repository_name_input = var.repository_name_override == null ? "" : trimspace(var.repository_name_override)
  repository_name       = length(local.repository_name_input) > 0 ? var.repository_name_override : "${var.name_prefix}-${var.service_name}"
  replication_filters   = length(var.replication_filter_prefixes) > 0 ? var.replication_filter_prefixes : [local.repository_name]
}

data "aws_caller_identity" "current" {}

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

resource "aws_ecr_replication_configuration" "this" {
  count = var.enable_replication ? 1 : 0

  replication_configuration {
    rule {
      dynamic "destination" {
        for_each = toset(var.replication_regions)

        content {
          region      = destination.value
          registry_id = data.aws_caller_identity.current.account_id
        }
      }

      dynamic "repository_filter" {
        for_each = toset(local.replication_filters)

        content {
          filter      = repository_filter.value
          filter_type = "PREFIX_MATCH"
        }
      }
    }
  }
}
