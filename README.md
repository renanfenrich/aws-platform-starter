# aws-platform-starter

This repo is how I set up a small AWS platform with Terraform when I want one service behind an ALB, a Postgres database, and enough guardrails to be safe. It is intentionally limited: the point is clarity and sane defaults, not a full platform.

## Purpose

This repo exists to show the baseline layout I use for a single-service AWS stack. It solves the "blank slate" problem by giving you working networking, compute, database, and basic alarms without a lot of moving parts. The infrastructure is real, but the scope is deliberately small for demonstration.

## Assumptions

- One public entry point (ALB) and one application service.
- Postgres is the only stateful dependency.
- Dev and prod are separate Terraform environments; you can run them in one account or split them later, but the repo does not manage multi-account plumbing.
- You can create VPC, ECS (Fargate, Fargate Spot, EC2 capacity providers), EC2 (self-managed Kubernetes), Auto Scaling, ALB, RDS, KMS, and SSM resources in your AWS account.

## Trade-offs I Made

- ECS Fargate is the prod default; dev uses Fargate Spot with Fargate fallback, and ECS on EC2 is available when host-level control is needed.
- Self-managed Kubernetes uses kubeadm with a single control plane and NodePort ingress behind the ALB; HA control plane and EKS are out of scope here.
- Dev uses a single NAT gateway to save cost; prod uses one per AZ for resilience.
- Alarms are intentionally minimal; you are expected to add app-specific signals.
- HTTPS is the default; HTTP is only allowed in dev to speed local testing.

## VPC Endpoints

- S3 and DynamoDB gateway endpoints are always enabled to keep common service traffic off the NAT and inside the AWS backbone.
- Interface endpoints (ECR api/dkr, CloudWatch Logs, SSM/ssmmessages/ec2messages) are enabled by default in prod and opt-in in dev to avoid extra hourly endpoint and ENI costs.
- This cuts NAT data processing and narrows egress paths without changing subnet layout or NAT behavior.

## Architecture Overview

Think of it as a straight line: user -> ALB -> compute -> RDS. The ALB lives in public subnets; compute runs as ECS tasks (Fargate, Fargate Spot, or EC2 capacity providers) or a self-managed Kubernetes cluster on EC2 in private subnets. NAT gateways handle outbound internet access for compute.

- Diagram and walkthrough: `docs/architecture.md`, `docs/architecture.mmd`, and optional generated `docs/architecture-aws.svg`
- Well-Architected mapping: `docs/well-architected.md`

## What Is Included

- VPC with public/private subnets across two AZs
- Internet-facing ALB with HTTPS (HTTP optional in dev)
- ECS service in private subnets with capacity providers (Fargate default, Fargate Spot in dev, EC2 optional)
- ECS EC2 capacity provider with a private Auto Scaling group (optional)
- Self-managed Kubernetes on EC2 with a single control plane and worker Auto Scaling group (optional)
- ECR repository per environment for application images
- RDS PostgreSQL with KMS encryption and Secrets Manager for the master password
- CloudWatch logs and a small set of alarms (ALB 5xx, ECS/EC2 CPU, RDS CPU)
- Remote state bootstrap with S3 native locking
- Demo Kubernetes manifests under `k8s/` (namespace, deployment, service, ingress)

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

- ALB access logs to S3 (prod default)
- VPC Flow Logs to CloudWatch (prod default)
- Optional WAF association for the ALB (off by default)

## Data Protection

RDS uses native automated backups with environment-aware retention (dev 3 days, prod 7 days) and encryption at rest; prod also enforces deletion protection and requires a final snapshot on delete. You can override `db_backup_retention_period`, `db_deletion_protection`, and `db_skip_final_snapshot` per environment, but doing so reduces recoverability; AWS Backup and cross-region DR are intentionally out of scope here.

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
  environments/
    dev/
    prod/
  modules/
    alb/
    k8s-ec2-infra/
    ecs-ec2-capacity/
    ecs/
    ecr/
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
- Permission to create VPC, ECS, EC2/Auto Scaling, ALB, RDS, KMS, SSM, and supporting resources

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

Wire notifications by setting `alarm_sns_topic_arn` in each environment `terraform.tfvars`.

If you enabled ACM in bootstrap, set `acm_certificate_arn` from the bootstrap output.

HTTPS requires an ACM certificate; either supply an existing ARN or enable the optional ACM DNS validation in bootstrap.

## Deploying an Environment

Example for dev:

```bash
cd environments/dev
terraform init -backend-config=backend.hcl
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

Prod is identical with `environments/prod`.

## Platform Selection

Set `platform` in `terraform.tfvars` to choose the compute layer:

- `ecs` (default): existing ECS behavior.
- `k8s_self_managed`: self-managed Kubernetes on EC2 with kubeadm.
- `eks`: reserved for future work (not implemented yet).

For Kubernetes:

1) Set `platform = "k8s_self_managed"` in `environments/dev/terraform.tfvars` or `environments/prod/terraform.tfvars`.
2) Apply the environment as usual.
3) Use SSM to access the control plane and apply the demo manifests:

```bash
aws ssm start-session --target <control_plane_instance_id> --region us-east-1
sudo -i
export KUBECONFIG=/etc/kubernetes/admin.conf
kubectl apply -k k8s/overlays/dev
```

Use `k8s/overlays/prod` for prod.

## Configuration Highlights

- HTTPS is always enabled; HTTP is allowed only when `allow_http = true` (dev only).
- RDS master password is managed by AWS and stored in Secrets Manager.
- ECS tasks run as a non-root user by default (`container_user`).
- Container images default to the environment ECR repository plus `image_tag`; set `container_image` to override.
- `platform` selects `ecs` or `k8s_self_managed` (with `eks` reserved for future use).
- `ecs_capacity_mode` switches between `fargate`, `fargate_spot`, and `ec2` capacity providers.
- ECS settings are ignored when `platform = "k8s_self_managed"`.
- ECS autoscaling is opt-in via `enable_autoscaling` and uses CPU target tracking; tune min/max/target/cooldowns per environment.
- Fargate Spot mode uses a weighted capacity provider strategy with FARGATE fallback.
- EC2 capacity providers use SSM by default; no public SSH ingress is configured.
- Provide `ec2_user_data` to extend ECS container instance bootstrap when using EC2 capacity.
- Self-managed Kubernetes uses kubeadm and a NodePort ingress behind the ALB.
- `prevent_destroy` can be enabled in prod to protect critical resources.

## CI/CD

GitHub Actions runs formatting, validation, linting, security checks, and tests. It is a quality gate, not a deployment pipeline.

## Testing

`tests/terraform/network.tftest.hcl` uses Terraform test + mock provider to validate module behavior without AWS credentials.

## Documentation

- `docs/project-overview.md` — repository layout, root stacks, and environment model.
- `docs/architecture.md` — architecture walkthrough and diagram.
- `docs/architecture-aws.svg` — optional AWS icon diagram.
- `docs/runbook.md` — operational runbook.
- `docs/well-architected.md` — pillar mapping and trade-offs.
- `docs/costs.md` — cost drivers and optimizations.
- `docs/decisions.md` — key design decisions.

## Notes on Costs and Safety

- NAT gateways, compute, and Multi-AZ RDS are the dominant costs in production.
- Dev defaults are cost-aware (single NAT, smaller instances).
- Use `make cost` (Infracost) for rough deltas; it requires `INFRACOST_API_KEY` and AWS read-only credentials (see `docs/costs.md`).
- Always review changes in `prod` with `prevent_destroy = true`.

## Next Steps

- Replace `CHANGE_ME` placeholders in tfvars and backend configs.
- Adjust container image and environment variables for your service.
- Add application-specific alarms and dashboards.
