# Budget

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_budgets_budget.monthly](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/budgets_budget) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_budget_limit_usd"></a> [budget\_limit\_usd](#input\_budget\_limit\_usd) | Monthly budget limit in USD. | `number` | n/a | yes |
| <a name="input_budget_name"></a> [budget\_name](#input\_budget\_name) | Name for the monthly cost budget. | `string` | n/a | yes |
| <a name="input_cost_filters"></a> [cost\_filters](#input\_cost\_filters) | Cost filters to scope the budget (for example, TagKeyValue). | `map(list(string))` | `{}` | no |
| <a name="input_critical_threshold_percent"></a> [critical\_threshold\_percent](#input\_critical\_threshold\_percent) | Critical threshold percentage of the budget. | `number` | n/a | yes |
| <a name="input_notification_emails"></a> [notification\_emails](#input\_notification\_emails) | Email recipients for budget alerts. | `list(string)` | `[]` | no |
| <a name="input_notification_sns_topic_arn"></a> [notification\_sns\_topic\_arn](#input\_notification\_sns\_topic\_arn) | SNS topic ARN for budget alerts. | `string` | `""` | no |
| <a name="input_warning_threshold_percent"></a> [warning\_threshold\_percent](#input\_warning\_threshold\_percent) | Warning threshold percentage of the budget. | `number` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_budget_arn"></a> [budget\_arn](#output\_budget\_arn) | ARN of the monthly cost budget. |
| <a name="output_budget_limit_usd"></a> [budget\_limit\_usd](#output\_budget\_limit\_usd) | Monthly budget limit in USD. |
| <a name="output_budget_name"></a> [budget\_name](#output\_budget\_name) | Name of the monthly cost budget. |
| <a name="output_critical_threshold_percent"></a> [critical\_threshold\_percent](#output\_critical\_threshold\_percent) | Critical threshold percentage. |
| <a name="output_warning_threshold_percent"></a> [warning\_threshold\_percent](#output\_warning\_threshold\_percent) | Warning threshold percentage. |
<!-- END_TF_DOCS -->
