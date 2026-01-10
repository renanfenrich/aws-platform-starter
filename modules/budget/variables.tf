variable "budget_name" {
  type        = string
  description = "Name for the monthly cost budget."

  validation {
    condition     = length(trimspace(var.budget_name)) > 0
    error_message = "budget_name must not be empty."
  }
}

variable "budget_limit_usd" {
  type        = number
  description = "Monthly budget limit in USD."

  validation {
    condition     = var.budget_limit_usd > 0
    error_message = "budget_limit_usd must be greater than 0."
  }
}

variable "warning_threshold_percent" {
  type        = number
  description = "Warning threshold percentage of the budget."

  validation {
    condition     = var.warning_threshold_percent > 0 && var.warning_threshold_percent < 100
    error_message = "warning_threshold_percent must be between 0 and 100."
  }
}

variable "critical_threshold_percent" {
  type        = number
  description = "Critical threshold percentage of the budget."

  validation {
    condition     = var.critical_threshold_percent > var.warning_threshold_percent && var.critical_threshold_percent <= 100
    error_message = "critical_threshold_percent must be greater than warning_threshold_percent and <= 100."
  }
}

variable "notification_emails" {
  type        = list(string)
  description = "Email recipients for budget alerts."
  default     = []

  validation {
    condition = alltrue([
      for email in var.notification_emails : length(trimspace(email)) > 0
    ])
    error_message = "notification_emails must not contain empty values."
  }

  validation {
    condition     = length(var.notification_emails) > 0 || length(trimspace(var.notification_sns_topic_arn)) > 0
    error_message = "At least one notification target is required (notification_emails or notification_sns_topic_arn)."
  }
}

variable "notification_sns_topic_arn" {
  type        = string
  description = "SNS topic ARN for budget alerts."
  default     = ""
}

variable "cost_filters" {
  type        = map(list(string))
  description = "Cost filters to scope the budget (for example, TagKeyValue)."
  default     = {}
}
