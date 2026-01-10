# FinOps Model

This repo treats cost as a system property: estimate before deploy, enforce during deploy, and monitor after deploy. The goal is repeatable, testable governance without manual console steps.

## Cost Lifecycle

### Pre-deploy: estimate
- CI runs Infracost across `bootstrap/`, `environments/dev`, and `environments/prod` using `infracost.yml`.
- Each environment includes `infracost.tfvars` to disable deploy-time enforcement while Infracost runs, keeping estimates deterministic.
- The JSON report is stored as a CI artifact and summarized in the PR job output.

### Deploy-time: enforce
- `estimated_monthly_cost` is a required input for `terraform plan/apply` when enforcement is enabled.
- The deploy guardrail compares `estimated_monthly_cost` against the hard budget threshold and blocks the run when it is exceeded.
- This keeps Terraform responsible for enforcement while CI remains responsible for estimation.

### Post-deploy: monitor
- Every environment creates an AWS Budget with warning and forecasted thresholds.
- Budget alerts route to email and/or SNS, using the same SNS topic used for infrastructure alarms when provided.
- Anomaly detection is not configured by default; add it only if you want to manage the extra signal and cost category setup.

## Environment Cost Rules

| Environment | Cost posture | Spot usage | Budgets |
| --- | --- | --- | --- |
| dev | `cost_optimized` | Spot-first (`fargate_spot` default) | Higher tolerance thresholds |
| prod | `stability_first` | Spot allowed only with `allow_spot_in_prod = true` | Stricter thresholds |

These rules are enforced via variable validation and defaults in each environment.

## Ownership and Allocation

Required tags:
- `Project`: repo-level project identifier
- `Environment`: `dev` or `prod`
- `Service`: logical service name (for cost attribution)
- `Owner`: team or individual responsible for spend
- `CostCenter`: chargeback/showback key
- `ManagedBy`: `Terraform`
- `Repository`: repo identifier

Tag validation is enforced in root stacks and modules. Cost allocation in AWS Budgets uses the `Environment` tag, which must be activated in the AWS Billing console (this step cannot be automated with Terraform).

## Alert Routing and Escalation

- `budget_notification_emails` defines who receives budget alerts.
- `budget_sns_topic_arn` overrides the SNS destination; if unset, `alarm_sns_topic_arn` is used.
- Alerts are progressive: warning on actual cost, critical on forecasted cost.

Escalation path:
1) Budget warning (email/SNS) → review recent deploy and cost estimate.
2) Budget forecast alert → reduce spend or adjust budget deliberately.
3) Deploy-time hard threshold → block deploy until estimate or budget is updated.

## Testing Guardrails

Terraform tests assert:
- Budgets exist per environment.
- Required tags are present on representative resources.
- Cost posture rules and spot usage restrictions are enforced.
- Deploy-time enforcement blocks when estimates exceed hard limits.

## Known Limitations

- Infracost provides estimates, not exact bills; usage-based charges still require monitoring.
- AWS cost allocation tags must be manually activated once per account.
- Budget enforcement blocks deploys only when `estimated_monthly_cost` is provided.
