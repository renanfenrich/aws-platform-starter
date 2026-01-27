resource "terraform_data" "cost_enforcement" {
  input = var.estimated_monthly_cost

  lifecycle {
    precondition {
      condition     = !var.enforce_cost_controls || (var.estimated_monthly_cost != null && var.estimated_monthly_cost <= local.budget_hard_limit_usd)
      error_message = format("Estimated monthly cost (%s) exceeds the hard limit (%.2f). Run Infracost and set estimated_monthly_cost before deploying.", local.estimated_cost_label, local.budget_hard_limit_usd)
    }
  }
}

module "budget" {
  source = "../../modules/budget"

  budget_name                = "${local.name_prefix}-monthly"
  budget_limit_usd           = var.budget_limit_usd
  warning_threshold_percent  = var.budget_warning_threshold_percent
  critical_threshold_percent = var.budget_hard_limit_percent
  notification_emails        = var.budget_notification_emails
  notification_sns_topic_arn = local.budget_sns_topic_arn
  cost_filters               = local.budget_cost_filters
}
