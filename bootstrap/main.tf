data "aws_caller_identity" "current" {}

locals {
  log_bucket_name = var.log_bucket_name != null && length(trimspace(var.log_bucket_name)) > 0 ? var.log_bucket_name : "${var.state_bucket_name}-logs"
  alb_access_logs_bucket_name = var.alb_access_logs_bucket_name != null && length(trimspace(var.alb_access_logs_bucket_name)) > 0 ? var.alb_access_logs_bucket_name : lower("${var.project_name}-${var.environment}-${data.aws_caller_identity.current.account_id}-${var.region_short}-alb-logs")
  name_prefix     = "${var.project_name}-${var.environment}"
  sns_topic_name  = "${local.name_prefix}-${var.region_short}-infra-alerts"
  sns_emails = toset([
    for email in var.sns_email_subscriptions : trimspace(email)
    if length(trimspace(email)) > 0
  ])
  create_acm_certificate = length(trimspace(var.acm_domain_name)) > 0
  create_acm_validation  = local.create_acm_certificate && length(trimspace(var.acm_zone_id)) > 0
}

data "aws_iam_policy_document" "state_kms" {
  statement {
    sid = "AllowRootAccount"

    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    sid = "AllowS3LogDelivery"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["logging.s3.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:s3:::${var.state_bucket_name}"]
    }
  }

  statement {
    sid = "AllowAlbLogDelivery"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["logdelivery.elasticloadbalancing.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  statement {
    sid = "AllowSnsEncryption"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant"
    ]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }
  }
}

resource "aws_kms_key" "state" {
  description             = "KMS key for Terraform state, logs, and SNS encryption"
  deletion_window_in_days = var.kms_deletion_window_in_days
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.state_kms.json

  tags = var.tags
}

resource "aws_kms_alias" "state" {
  name          = "alias/${var.state_bucket_name}-state"
  target_key_id = aws_kms_key.state.key_id
}

resource "aws_sns_topic" "infra_notifications" {
  name              = local.sns_topic_name
  kms_master_key_id = aws_kms_alias.state.name

  tags = merge(var.tags, {
    Name = local.sns_topic_name
  })
}

resource "aws_sns_topic_subscription" "email" {
  for_each = local.sns_emails

  topic_arn = aws_sns_topic.infra_notifications.arn
  protocol  = "email"
  endpoint  = each.value
}

resource "aws_s3_bucket" "state" {
  bucket        = var.state_bucket_name
  force_destroy = var.force_destroy

  lifecycle {
    prevent_destroy = true
  }

  tags = merge(var.tags, {
    Name = var.state_bucket_name
  })
}

# tfsec:ignore:aws-s3-enable-bucket-logging
resource "aws_s3_bucket" "state_logs" {
  bucket        = local.log_bucket_name
  force_destroy = var.force_destroy

  lifecycle {
    prevent_destroy = true
  }

  tags = merge(var.tags, {
    Name = local.log_bucket_name
  })
}

resource "aws_s3_bucket_ownership_controls" "state_logs" {
  bucket = aws_s3_bucket.state_logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "state_logs" {
  bucket = aws_s3_bucket.state_logs.id
  acl    = "log-delivery-write"

  depends_on = [aws_s3_bucket_ownership_controls.state_logs]
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "state_logs" {
  bucket = aws_s3_bucket.state_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.state.arn
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state_logs" {
  bucket = aws_s3_bucket.state_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.state.arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "state_logs" {
  bucket = aws_s3_bucket.state_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_logging" "state" {
  bucket        = aws_s3_bucket.state.id
  target_bucket = aws_s3_bucket.state_logs.id
  target_prefix = "state/"

  depends_on = [aws_s3_bucket_acl.state_logs]
}

resource "aws_s3_bucket" "alb_access_logs" {
  bucket        = local.alb_access_logs_bucket_name
  force_destroy = var.force_destroy

  lifecycle {
    prevent_destroy = true
  }

  tags = merge(var.tags, {
    Name = local.alb_access_logs_bucket_name
  })
}

resource "aws_s3_bucket_ownership_controls" "alb_access_logs" {
  bucket = aws_s3_bucket.alb_access_logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "alb_access_logs" {
  bucket = aws_s3_bucket.alb_access_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.state.arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "alb_access_logs" {
  bucket = aws_s3_bucket.alb_access_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "alb_access_logs" {
  bucket = aws_s3_bucket.alb_access_logs.id

  rule {
    id     = "log-retention"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    expiration {
      days = 180
    }
  }
}

data "aws_iam_policy_document" "alb_access_logs" {
  statement {
    sid     = "AllowAlbLogDelivery"
    actions = ["s3:PutObject"]
    resources = [
      "${aws_s3_bucket.alb_access_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
    ]

    principals {
      type        = "Service"
      identifiers = ["logdelivery.elasticloadbalancing.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    dynamic "condition" {
      for_each = length(var.alb_access_logs_source_arns) > 0 ? [1] : []

      content {
        test     = "ArnLike"
        variable = "aws:SourceArn"
        values   = var.alb_access_logs_source_arns
      }
    }
  }

  statement {
    sid     = "AllowAlbLogDeliveryAclCheck"
    actions = ["s3:GetBucketAcl"]
    resources = [
      aws_s3_bucket.alb_access_logs.arn
    ]

    principals {
      type        = "Service"
      identifiers = ["logdelivery.elasticloadbalancing.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    dynamic "condition" {
      for_each = length(var.alb_access_logs_source_arns) > 0 ? [1] : []

      content {
        test     = "ArnLike"
        variable = "aws:SourceArn"
        values   = var.alb_access_logs_source_arns
      }
    }
  }
}

resource "aws_s3_bucket_policy" "alb_access_logs" {
  bucket = aws_s3_bucket.alb_access_logs.id
  policy = data.aws_iam_policy_document.alb_access_logs.json
}


resource "aws_acm_certificate" "app" {
  count = local.create_acm_certificate ? 1 : 0

  domain_name               = var.acm_domain_name
  validation_method         = "DNS"
  subject_alternative_names = var.acm_subject_alternative_names

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-acm"
  })
}

resource "aws_route53_record" "acm_validation" {
  for_each = local.create_acm_validation ? {
    for option in aws_acm_certificate.app[0].domain_validation_options : option.domain_name => {
      name   = option.resource_record_name
      record = option.resource_record_value
      type   = option.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.acm_zone_id
}

resource "aws_acm_certificate_validation" "app" {
  count = local.create_acm_validation ? 1 : 0

  certificate_arn         = aws_acm_certificate.app[0].arn
  validation_record_fqdns = [for record in aws_route53_record.acm_validation : record.fqdn]
}
