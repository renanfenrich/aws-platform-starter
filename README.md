# aws-production-platform-terraform

This repo is how I set up a small AWS platform with Terraform when I want one service behind an ALB, a Postgres database, and enough guardrails to be safe. It is intentionally limited: the point is clarity and sane defaults, not a full platform.

## Purpose

This repo exists to show the baseline layout I use for a single-service AWS stack. It solves the "blank slate" problem by giving you working networking, compute, database, and basic alarms without a lot of moving parts. The infrastructure is real, but the scope is deliberately small for demonstration.

## Assumptions

- One public entry point (ALB) and one application service.
- Postgres is the only stateful dependency.
- Dev and prod are separate Terraform environments; you can run them in one account or split them later, but the repo does not manage multi-account plumbing.
- You can create VPC, ECS (Fargate, Fargate Spot, EC2 capacity providers), Auto Scaling, ALB, RDS, and KMS resources in your AWS account.

## Trade-offs I Made

- ECS Fargate is the prod default; dev uses Fargate Spot with Fargate fallback, and ECS on EC2 is available when host-level control is needed.
- Dev uses a single NAT gateway to save cost; prod uses one per AZ for resilience.
- Alarms are intentionally minimal; you are expected to add app-specific signals.
- HTTPS is the default; HTTP is only allowed in dev to speed local testing.

## Architecture Overview

Think of it as a straight line: user -> ALB -> compute -> RDS. The ALB lives in public subnets; ECS tasks (Fargate, Fargate Spot, or EC2 capacity providers) and RDS live in private subnets. NAT gateways handle outbound internet access for compute.

- Diagram and walkthrough: `docs/architecture.md` and `docs/architecture.mmd`
- Well-Architected mapping: `docs/well-architected.md`

## What Is Included

- VPC with public/private subnets across two AZs
- Internet-facing ALB with HTTPS (HTTP optional in dev)
- ECS service in private subnets with capacity providers (Fargate default, Fargate Spot in dev, EC2 optional)
- ECS EC2 capacity provider with a private Auto Scaling group (optional)
- RDS PostgreSQL with KMS encryption and Secrets Manager for the master password
- CloudWatch logs and a small set of alarms (ALB 5xx, ECS/EC2 CPU, RDS CPU)
- Remote state bootstrap with S3 and DynamoDB locking

## What Is Intentionally Not Included

- WAF, advanced edge security, or bot protection
- Autoscaling policies, blue/green deployments, or canaries
- Centralized logging or metrics beyond baseline CloudWatch alarms
- Multi-account orchestration or organization-level controls

## How This Would Evolve in a Real Production Environment

If this were running a real product, I would add:

- WAF and ALB access logs, plus centralized log storage
- Autoscaling for ECS and tighter RDS scaling/backup policies
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
  environments/
    dev/
    prod/
  modules/
    alb/
    ecs-ec2-capacity/
    ecs/
    network/
    observability/
    rds/
  bootstrap/
  tests/
  .github/workflows/
```

## Prerequisites

- Terraform >= 1.6
- AWS credentials via environment variables, SSO, or profile (no hardcoded keys)
- Permission to create VPC, ECS, EC2/Auto Scaling, ALB, RDS, KMS, and supporting resources

## Bootstrap Remote State

State and locking are created once from `bootstrap/`.

```bash
cd bootstrap
terraform init
terraform apply \
  -var="aws_region=us-east-1" \
  -var="state_bucket_name=your-terraform-state" \
  -var="lock_table_name=your-terraform-locks"
```

Update `environments/dev/backend.hcl` and `environments/prod/backend.hcl` with the bucket and table names.

## Deploying an Environment

Example for dev:

```bash
cd environments/dev
terraform init -backend-config=backend.hcl
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

Prod is identical with `environments/prod`.

## Configuration Highlights

- HTTPS is always enabled; HTTP is allowed only when `allow_http = true` (dev only).
- RDS master password is managed by AWS and stored in Secrets Manager.
- ECS tasks run as a non-root user by default (`container_user`).
- `ecs_capacity_mode` switches between `fargate`, `fargate_spot`, and `ec2` capacity providers.
- Fargate Spot mode uses a weighted capacity provider strategy with FARGATE fallback.
- EC2 capacity providers use SSM by default; no public SSH ingress is configured.
- Provide `ec2_user_data` to extend ECS container instance bootstrap when using EC2 capacity.
- `prevent_destroy` can be enabled in prod to protect critical resources.

## CI/CD

GitHub Actions runs formatting, validation, linting, security checks, and tests. It is a quality gate, not a deployment pipeline.

## Testing

`tests/terraform/network.tftest.hcl` uses Terraform test + mock provider to validate module behavior without AWS credentials.

## Documentation

- `docs/architecture.md` — architecture walkthrough and diagram.
- `docs/runbook.md` — operational runbook.
- `docs/well-architected.md` — pillar mapping and trade-offs.
- `docs/costs.md` — cost drivers and optimizations.
- `docs/decisions.md` — key design decisions.

## Notes on Costs and Safety

- NAT gateways, compute, and Multi-AZ RDS are the dominant costs in production.
- Dev defaults are cost-aware (single NAT, smaller instances).
- Always review changes in `prod` with `prevent_destroy = true`.

## Next Steps

- Replace `CHANGE_ME` placeholders in tfvars and backend configs.
- Adjust container image and environment variables for your service.
- Add application-specific alarms and dashboards.
