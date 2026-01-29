# FinOps Model

This repo treats cost as a system property: estimate before deploy, enforce during deploy, and monitor after deploy. The goal is repeatable, testable governance without manual console steps.

## Cost Lifecycle

### Pre-deploy: estimate
- CI runs Infracost across `bootstrap/`, `environments/dev`, `environments/prod`, and `environments/dr` using `infracost.yml` when the required secrets are present.
- Each environment includes `infracost.tfvars` to disable deploy-time enforcement while Infracost runs, keeping estimates deterministic.
- The PR job writes a summary table via `scripts/finops-ci.sh` and uploads the JSON report as an artifact.

### Deploy-time: enforce
- `enforce_cost_controls` defaults to `true` in the environments; when it is enabled, `estimated_monthly_cost` must be provided.
- The deploy guardrail compares `estimated_monthly_cost` against the hard budget threshold and blocks the run when it is exceeded.
- This keeps Terraform responsible for enforcement while CI remains responsible for estimation. To bypass enforcement, set `enforce_cost_controls = false` explicitly.

### Post-deploy: monitor
- Every environment creates an AWS Budget with warning and forecasted thresholds.
- Budget alerts route to email and/or SNS, using `budget_notification_emails` and/or `budget_sns_topic_arn` (which defaults to `alarm_sns_topic_arn` when set).
- Anomaly detection is not configured by default; add it only if you want to manage the extra signal and cost category setup.

## Environment Cost Rules

| Environment | Cost posture | Spot usage | Budgets |
| --- | --- | --- | --- |
| dev | `cost_optimized` | Spot-first (`fargate_spot` default) | Higher tolerance thresholds |
| prod | `stability_first` | Spot allowed only with `allow_spot_in_prod = true` | Stricter thresholds |
| dr | `cost_optimized` | Spot allowed (opt-in) | Minimal baseline budgets; scale up during incidents |

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

Guardrail coverage is tracked in `docs/tests.md`.

## Known Limitations

- Infracost provides estimates, not exact bills; usage-based charges still require monitoring.
- AWS cost allocation tags must be manually activated once per account.
- Budget enforcement blocks deploys only when `estimated_monthly_cost` is provided and `enforce_cost_controls = true`.
