locals {
  notification_emails = toset([
    for email in var.notification_emails : trimspace(email)
    if length(trimspace(email)) > 0
  ])
  notification_sns_topic_arn = length(trimspace(var.notification_sns_topic_arn)) > 0 ? var.notification_sns_topic_arn : null
}

resource "aws_budgets_budget" "monthly" {
  name         = var.budget_name
  budget_type  = "COST"
  limit_amount = var.budget_limit_usd
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  dynamic "cost_filter" {
    for_each = var.cost_filters
    content {
      name   = cost_filter.key
      values = cost_filter.value
    }
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    notification_type          = "ACTUAL"
    threshold                  = var.warning_threshold_percent
    threshold_type             = "PERCENTAGE"
    subscriber_email_addresses = tolist(local.notification_emails)
    subscriber_sns_topic_arns  = local.notification_sns_topic_arn != null ? [local.notification_sns_topic_arn] : []
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    notification_type          = "FORECASTED"
    threshold                  = var.critical_threshold_percent
    threshold_type             = "PERCENTAGE"
    subscriber_email_addresses = tolist(local.notification_emails)
    subscriber_sns_topic_arns  = local.notification_sns_topic_arn != null ? [local.notification_sns_topic_arn] : []
  }
}
