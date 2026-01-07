# aws-production-platform-terraform

Production-grade AWS platform scaffolding with Terraform. The goal is to demonstrate senior-level infrastructure design, security, and operational maturity with minimal components and maximum correctness.

## What This Repository Provisions

- VPC with public/private subnets across two AZs.
- Internet-facing ALB (HTTPS) with optional HTTP only for dev.
- ECS Fargate service in private subnets.
- RDS PostgreSQL in private subnets with KMS encryption and Secrets Manager integration.
- CloudWatch logs and alarms (ALB 5xx, ECS CPU, RDS CPU).
- Remote state with S3 + DynamoDB locking (bootstrap folder).

## Architecture

- See `docs/architecture.md` and `docs/architecture.mmd` for the diagram.
- Well-Architected mapping: `docs/well-architected.md`.

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
- Access to create VPC, ECS, ALB, RDS, KMS, and supporting resources

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

- HTTPS is always enabled; HTTP is allowed only when `allow_http = true` (dev).
- RDS master password is managed by AWS and stored in Secrets Manager.
- ECS tasks run as a non-root user (`container_user`).
- `prevent_destroy` can be enabled in prod to protect critical resources.

## CI/CD

GitHub Actions runs:

- `terraform fmt -check`
- `terraform validate` (dev and prod)
- `tflint`
- `tfsec`
- `terraform-docs` check
- `terraform test`

## Testing

`tests/terraform/network.tftest.hcl` uses Terraform test + mock provider to validate module behavior without AWS credentials.

## Documentation

- `docs/architecture.md` — architecture overview and diagram.
- `docs/runbook.md` — operational runbook.
- `docs/well-architected.md` — pillar mapping and trade-offs.
- `docs/costs.md` — cost drivers and optimizations.
- `docs/decisions.md` — key design decisions.

## Notes on Costs and Safety

- NAT gateways and Multi-AZ RDS are the dominant costs in production.
- Dev defaults are cost-aware (single NAT, smaller instances).
- Always review changes in `prod` with `prevent_destroy = true`.

## Next Steps

- Replace `CHANGE_ME` placeholders in tfvars and backend configs.
- Adjust container image and environment variables for your service.
- Add application-specific alarms and dashboards.
