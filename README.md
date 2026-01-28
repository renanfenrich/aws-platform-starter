# aws-platform-starter

This repo is how I set up a small AWS platform with Terraform when I want one service behind an ALB, a Postgres database, and enough guardrails to be safe. It is intentionally limited: the point is clarity and sane defaults, not a full platform.

## Purpose

This repo exists to show the baseline layout I use for a single-service AWS stack. It solves the "blank slate" problem by giving you working networking, compute, database, and basic alarms without a lot of moving parts. The infrastructure is real, but the scope is deliberately small for demonstration.

## Assumptions

- Default public entry point is the ALB for the main application service; an optional API Gateway + Lambda path can be enabled for lightweight endpoints.
- Postgres is the only stateful dependency.
- Dev and prod are separate Terraform environments, with an optional pilot-light DR environment; you can run them in one account or split them later, but the repo does not manage multi-account plumbing.
- You can create VPC, ALB, ECS (Fargate/Fargate Spot/EC2 capacity providers), EC2/Auto Scaling, ECR, RDS, KMS, IAM, SSM, CloudWatch, and Budgets resources in your AWS account.

## Trade-offs I Made

- ECS Fargate is the prod default; dev uses Fargate Spot with Fargate fallback, and ECS on EC2 is available when host-level control is needed.
- Self-managed Kubernetes uses kubeadm with a single control plane and NodePort ingress behind the ALB; EKS is available when I want a managed control plane with a private API endpoint and an admin runner for access.
- Dev uses a single NAT gateway to save cost; prod uses one per AZ for resilience.
- Alarms are intentionally minimal; you are expected to add app-specific signals.
- HTTPS is the default; HTTP is only allowed in dev to speed local testing.

## VPC Endpoints

- S3 and DynamoDB gateway endpoints are always enabled to keep common service traffic off the NAT and inside the AWS backbone.
- Interface endpoints (ECR api/dkr, CloudWatch Logs, SSM/ssmmessages/ec2messages) are enabled by default in prod and opt-in in dev to avoid extra hourly endpoint and ENI costs.
- This cuts NAT data processing and narrows egress paths without changing subnet layout or NAT behavior.

## Architecture Overview

Think of it as a straight line: user -> ALB -> compute -> RDS. The ALB lives in public subnets; compute runs as ECS tasks (Fargate, Fargate Spot, or EC2 capacity providers) or Kubernetes (self-managed on EC2 or EKS) in private subnets. NAT gateways handle outbound internet access for compute, and interface endpoints (when enabled) keep ECR/Logs/SSM traffic inside the VPC. When `enable_serverless_api = true`, API Gateway + Lambda is a parallel ingress path.

- Diagram and walkthrough: `docs/architecture.md`, `docs/architecture.mmd`, and generated `docs/architecture.svg`
- Well-Architected mapping: `docs/well-architected.md`

## What Is Included

- VPC with public/private subnets across two AZs
- Internet-facing ALB with HTTPS (HTTP optional in dev)
- ECS service in private subnets with capacity providers (Fargate default, Fargate Spot in dev, EC2 optional)
- ECS EC2 capacity provider with a private Auto Scaling group (optional)
- Self-managed Kubernetes on EC2 with a single control plane and worker Auto Scaling group (optional)
- EKS cluster with a managed node group and optional admin runner (optional)
- ECR repository per environment (immutable tags, scan-on-push, lifecycle policy for untagged images)
- API Gateway HTTP API + Lambda serverless API (optional)
- RDS PostgreSQL with KMS encryption and Secrets Manager-managed master password
- Baseline CloudWatch logs, alarms, and an environment dashboard
- VPC endpoints for S3/DynamoDB (gateway) and optional interface endpoints (ECR/Logs/SSM)
- AWS Budgets per environment + deploy-time cost enforcement
- Remote state bootstrap with S3 native locking, KMS key, SNS topic, and ALB log bucket
- Pilot-light DR environment (opt-in) with optional ECR replication and AWS Backup copy hooks
- Demo Kubernetes manifests under `k8s/base` and `k8s/overlays`

## Autoscaling

ECS service autoscaling is optional and uses target tracking on average CPU utilization to scale `desired_count`. It is intentionally single-metric and deterministic. Terraform still sets `desired_count` on apply, so keep it aligned with your autoscaling minimum.

Defaults and posture:
- Dev: disabled by default. If enabled, min=1, max=2, target CPU=60%, cooldowns=60s.
- Prod: disabled by default because `environments/prod/terraform.tfvars` sets `desired_count = 2`. If you enable it, recommended values are min=2, max=6, target CPU=50%, cooldowns=120s.

Enable or disable it with:
- `enable_autoscaling = true|false`
- `autoscaling_min_capacity`, `autoscaling_max_capacity`, `autoscaling_target_cpu`
- `autoscaling_scale_in_cooldown`, `autoscaling_scale_out_cooldown`

## Production Hardening

- ALB access logs to S3 (prod default). Set `alb_access_logs_bucket` to the bootstrap output `alb_access_logs_bucket_name`.
- VPC Flow Logs to CloudWatch (prod default)
- Optional WAF association for the ALB (off by default)

## Data Protection

RDS uses native automated backups with environment-aware retention (dev 3 days, prod 7 days) and encryption at rest; prod also enforces deletion protection and requires a final snapshot on delete. You can override `db_backup_retention_period`, `db_deletion_protection`, and `db_skip_final_snapshot` per environment, but doing so reduces recoverability. Optional AWS Backup copy and pilot-light DR are now supported; see `docs/dr-plan.md` for the cross-region workflow.

RDS manages the master password and stores it in Secrets Manager. ECS tasks inject the secret ARN as `DB_SECRET` by default (the value is the JSON payload from Secrets Manager). Kubernetes secrets are not wired in by default; you need to fetch them yourself if you run `k8s_self_managed`.

## What Is Intentionally Not Included

- Managed WAF rule sets, advanced edge security, or bot protection (WAF attachment is optional but not configured here)
- Advanced autoscaling policies (multi-metric, request-based, step scaling), blue/green deployments, or canaries
- Centralized logging or metrics beyond baseline CloudWatch alarms (ALB access logs and VPC Flow Logs are minimal, not a full log platform)
- Multi-account orchestration or organization-level controls

## How This Would Evolve in a Real Production Environment

If this were running a real product, I would add:

- Managed WAF rules and a centralized log pipeline
- More advanced autoscaling (request-based, multi-metric) and tighter RDS scaling/backup policies
- CI/CD that deploys and rolls back safely
- Multi-account separation (at least a dedicated prod account)
- A real observability stack (dashboards, tracing, SLOs)

## Repository Layout

```
/
  README.md
  SECURITY.md
  CONTRIBUTING.md
  LICENSE
  Makefile
  docs/
  k8s/
    base/
    overlays/
  environments/
    dev/
    prod/
    dr/
  modules/
    alb/
    apigw-lambda/
    backup-vault/
    budget/
    dns/
    k8s-ec2-infra/
    ecs-ec2-capacity/
    ecs/
    ecr/
    eks/
    network/
    observability/
    rds/
  bootstrap/
  tests/
    terraform/
  scripts/
  .github/workflows/
```

## Root Stack File Layout

Terraform treats all `*.tf` files in a directory as a single module. The environment roots are split by context to keep stacks readable; there is no functional difference from a single `main.tf`.

Standard file split (only create files when they have content):

- `versions.tf`: Terraform and provider version constraints.
- `providers.tf`: provider blocks and default tags.
- `backend.tf`: backend configuration (empty config block).
- `locals.tf`: locals for naming, tags, and computed values.
- `variables.tf`: root input variables.
- `data-sources.tf`: data sources (optional, for readability).
- `network.tf`: VPC, subnets, NAT, endpoints, routing.
- `security.tf`: security groups, WAF attachments, edge-related resources.
- `dns.tf`: Route 53 zones/records when DNS is enabled.
- `compute.tf`: ECS/EKS/K8s modules and serverless compute.
- `data.tf`: RDS and backup resources.
- `observability.tf`: logging, metrics, alarms, dashboards.
- `finops.tf`: budgets and cost guardrails.
- `outputs.tf`: root outputs.

## Prerequisites

- Terraform >= 1.11.0
- AWS credentials via environment variables, SSO, or profile (no hardcoded keys)
- Permission to create VPC, ECS, EC2/Auto Scaling, ALB, RDS, KMS, SSM, ECR, CloudWatch, and Budget resources

## Bootstrap First

Bootstrap creates the shared state bucket, KMS key, and notification resources needed by the environments. State locking uses S3 native lock files.

```bash
cp bootstrap/terraform.tfvars.example bootstrap/terraform.tfvars
terraform -chdir=bootstrap init
terraform -chdir=bootstrap plan -var-file=terraform.tfvars
terraform -chdir=bootstrap apply -var-file=terraform.tfvars
```

Use the outputs to update the backend configs:

- `environments/dev/backend.hcl` (or start from `environments/dev/backend.hcl.example`)
- `environments/prod/backend.hcl` (or start from `environments/prod/backend.hcl.example`)
- `environments/dr/backend.hcl` (optional, for pilot-light DR; start from `environments/dr/backend.hcl.example`)

Wire notifications by setting `alarm_sns_topic_arn` in each environment `terraform.tfvars` to the bootstrap `sns_topic_arn` output.

If you enabled ACM in bootstrap, set `acm_certificate_arn` from the bootstrap output.

HTTPS requires an ACM certificate; either supply an existing ARN or enable the optional ACM DNS validation in bootstrap.

## Deploying an Environment

Example for dev:

```bash
make plan ENV=dev platform=ecs
make apply ENV=dev platform=ecs
```

Prod is identical with `ENV=prod`. DR (optional) uses `ENV=dr`. The Makefile targets assume `backend.hcl` and `terraform.tfvars` are already populated.

## Platform Selection

Set `platform` in `terraform.tfvars` to choose the compute layer:

- `ecs` (default): existing ECS behavior.
- `k8s_self_managed`: self-managed Kubernetes on EC2 with kubeadm.
- `eks`: managed EKS cluster with a private API endpoint by default and an optional admin runner for kubectl.

For Kubernetes:

1) Set `platform = "k8s_self_managed"` in `environments/dev/terraform.tfvars` or `environments/prod/terraform.tfvars`.
2) Apply the environment as usual; when using the Makefile, pass `platform=k8s_self_managed` so it does not override the tfvars value.
3) Use the `cluster_access_instructions` output to access the control plane via SSM and apply the demo manifests:

```bash
terraform -chdir=environments/dev output -raw cluster_access_instructions
kubectl apply -k k8s/overlays/dev
```

Use `k8s/overlays/prod` for prod.

For EKS:

1) Set `platform = "eks"` in `environments/dev/terraform.tfvars` or `environments/prod/terraform.tfvars`.
2) Apply the environment as usual; when using the Makefile, pass `platform=eks` so it does not override the tfvars value.
3) Use the `cluster_access_instructions` output to connect to the admin runner via SSM and run `eks-kubeconfig`.

## Configuration Highlights

- HTTPS is always enabled; HTTP is allowed only when `allow_http = true` (dev only).
- RDS master password is managed by AWS and stored in Secrets Manager.
- ECS tasks run as a non-root user by default (`container_user`).
- Container images default to the environment ECR repository plus `image_tag`; set `container_image` to override. The resolved value is in the `resolved_container_image` output.
- `platform` selects `ecs`, `k8s_self_managed`, or `eks`.
- `ecs_capacity_mode` switches between `fargate`, `fargate_spot`, and `ec2` capacity providers; Fargate Spot in prod requires `allow_spot_in_prod = true`.
- ECS settings are ignored when `platform = "k8s_self_managed"`.
- ECS autoscaling is opt-in via `enable_autoscaling` and uses CPU target tracking; tune min/max/target/cooldowns per environment.
- Fargate Spot mode uses a weighted capacity provider strategy with FARGATE fallback.
- EC2 capacity providers use SSM by default; no public SSH ingress is configured.
- Provide `ec2_user_data` to extend ECS container instance bootstrap when using EC2 capacity.
- Self-managed Kubernetes uses kubeadm and a NodePort ingress behind the ALB.
- EKS defaults to a private API endpoint; set `eks_endpoint_public_access = true` and restrict `eks_endpoint_public_access_cidrs` if you need public access.
- `enable_serverless_api` toggles the API Gateway + Lambda module; use the `serverless_api_*` variables to tune CORS, X-Ray, and routes.
- Prod defaults enable alarms, flow logs, ALB access logs, and `prevent_destroy` for RDS.

## CI/CD

GitHub Actions runs `fmt-check`, `validate`, `lint`, `tfsec`, `docs-check`, and `terraform test`. A Kubernetes workflow runs `k8s-validate`, `k8s-lint`, `k8s-policy`, and `k8s-sec` when Kubernetes-related files change. An Infracost job runs on PRs when the required secrets are present, then posts a FinOps summary; CI is a quality gate, not a deployment pipeline. Repo setup steps and required secrets are documented in `docs/github-actions.md`.

## Testing

`make test` runs `terraform test` for bootstrap, `tests/terraform`, environments (dev/prod/dr), and the core modules (network, ALB, DNS, API Gateway + Lambda, backup vault, ECS, ECS EC2 capacity, EKS, K8s EC2 infra, RDS, observability) with backendless init.

## Engineering Standards

- Terraform skillbook: `docs/terraform/skillbook.md` (repo-local standards, checklists, and CI patterns).
- Attribution: `docs/terraform/ATTRIBUTION.md`.
- Kubernetes skillbook: `docs/kubernetes/skillbook.md` (repo-local standards, checklists, and policy rules).
- Local checks: `make fmt`, `make validate`, `make lint`, `make security`, `make docs`, `make test`.
- Kubernetes checks: `make k8s-fmt`, `make k8s-validate`, `make k8s-lint`, `make k8s-policy`, `make k8s-sec`.
- Module changes: update module docs and tests in the same PR; if a module is shared outside the repo, tag releases as `module-<name>-vX.Y.Z` with SemVer and a short release note (see the skillbook).

## Documentation

- `docs/README.md` — documentation index
- `docs/project-overview.md` — repository layout and environment model
- `docs/architecture.md` — architecture walkthrough and diagram
- `docs/runbook.md` — operational runbook
- `docs/dr-plan.md` — disaster recovery plan and procedures
- `docs/finops.md` — cost estimation and enforcement model
- `docs/tests.md` — test coverage and how to run
- `docs/decisions.md` — key design decisions
- `docs/well-architected.md` — pillar mapping and trade-offs
- `docs/costs.md` — cost drivers and optimizations

## Notes on Costs and Safety

- NAT gateways, compute, and Multi-AZ RDS are the dominant costs in production.
- Dev defaults are cost-aware (single NAT, smaller instances).
- Use `make cost` (Infracost) for rough deltas; it requires `INFRACOST_API_KEY` and AWS read-only credentials (see `docs/costs.md`).
- If `enforce_cost_controls = true` (default), you must provide `estimated_monthly_cost` via `TF_VAR_estimated_monthly_cost` before running plan/apply.
- Always review changes in `prod` with `prevent_destroy = true`.

## Next Steps

- Replace `CHANGE_ME` placeholders in tfvars and backend configs.
- Adjust container image and environment variables for your service.
- Add application-specific alarms and dashboards.
