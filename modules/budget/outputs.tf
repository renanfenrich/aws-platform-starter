output "budget_arn" {
  description = "ARN of the monthly cost budget."
  value       = aws_budgets_budget.monthly.arn
}

output "budget_name" {
  description = "Name of the monthly cost budget."
  value       = aws_budgets_budget.monthly.name
}

output "budget_limit_usd" {
  description = "Monthly budget limit in USD."
  value       = var.budget_limit_usd
}

output "warning_threshold_percent" {
  description = "Warning threshold percentage."
  value       = var.warning_threshold_percent
}

output "critical_threshold_percent" {
  description = "Critical threshold percentage."
  value       = var.critical_threshold_percent
}
