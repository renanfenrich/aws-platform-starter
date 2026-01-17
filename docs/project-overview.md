# Project Overview

## Overview
This repository is a small, production-minded AWS infrastructure stack built with Terraform.
It separates one-time bootstrap concerns from environment root stacks to keep state and prerequisites explicit.
Environments are composed from focused modules (networking, compute, data, observability) with clear boundaries.
Defaults prioritize safe-by-default behavior and make trade-offs visible (cost vs resilience, ECS vs self-managed K8s).
FinOps guardrails are built in via budgets, cost posture validation, and deploy-time checks.
Documentation is treated as part of the system: architecture, runbook, and decisions live alongside the code.

## Repository Structure (Tree)
```
.
├── AGENTS.md
├── README.md
├── SECURITY.md
├── CONTRIBUTING.md
├── LICENSE
├── Makefile
├── bootstrap
│   ├── README.md
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── versions.tf
│   ├── provider.tf
│   ├── terraform.tfvars
│   ├── terraform.tfvars.example
│   └── bootstrap.tftest.hcl
├── environments
│   ├── dev
│   │   ├── backend.tf
│   │   ├── backend.hcl
│   │   ├── backend.hcl.example
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── versions.tf
│   │   ├── terraform.tfvars
│   │   ├── infracost.tfvars
│   │   └── stack.tftest.hcl
│   └── prod
│       ├── backend.tf
│       ├── backend.hcl
│       ├── backend.hcl.example
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── versions.tf
│       ├── terraform.tfvars
│       ├── infracost.tfvars
│       └── stack.tftest.hcl
├── modules
│   ├── alb
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── versions.tf
│   │   ├── alb.tftest.hcl
│   │   └── README.md
│   ├── budget
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── ecs
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── versions.tf
│   │   ├── ecs.tftest.hcl
│   │   └── README.md
│   ├── ecs-ec2-capacity
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── versions.tf
│   │   ├── ecs-ec2-capacity.tftest.hcl
│   │   └── README.md
│   ├── ecr
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── versions.tf
│   │   └── README.md
│   ├── eks
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── versions.tf
│   │   ├── eks.tftest.hcl
│   │   ├── templates
│   │   │   └── admin-runner-user-data.sh.tpl
│   │   └── README.md
│   ├── k8s-ec2-infra
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── versions.tf
│   │   ├── k8s-ec2-infra.tftest.hcl
│   │   ├── templates
│   │   │   ├── control-plane-user-data.sh.tpl
│   │   │   └── worker-user-data.sh.tpl
│   │   └── README.md
│   ├── network
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── versions.tf
│   │   ├── network.tftest.hcl
│   │   └── README.md
│   ├── observability
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── versions.tf
│   │   ├── observability.tftest.hcl
│   │   └── README.md
│   └── rds
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── versions.tf
│       ├── rds.tftest.hcl
│       └── README.md
├── docs
│   ├── README.md
│   ├── project-overview.md
│   ├── architecture.md
│   ├── architecture.mmd
│   ├── runbook.md
│   ├── finops.md
│   ├── costs.md
│   ├── tests.md
│   ├── decisions.md
│   ├── well-architected.md
│   └── interview-talk-track.md
├── tests
│   └── terraform
│       ├── main.tf
│       ├── platform.tftest.hcl
│       ├── compute_mode.tftest.hcl
│       └── network.tftest.hcl
├── k8s
│   ├── README.md
│   ├── base
│   └── overlays
├── scripts
│   └── finops-ci.sh
├── .github
│   └── workflows
│       └── ci.yml
├── infracost.yml
├── infracost-usage-bootstrap.yml
├── infracost-usage-dev.yml
└── infracost-usage-prod.yml
```

Note: local caches and state (for example: `.terraform/`, `.infracost/`, and `terraform.tfstate*`) are ignored by git and are not part of the repo. The committed `terraform.tfvars` and `backend.hcl` files are placeholders; replace placeholder values (for example `CHANGE_ME` or zeroed ARNs) with your own.

## Key Directories and Responsibilities
- `bootstrap/`: One-time/account prerequisites (state bucket + logging bucket, ALB access log bucket, KMS key, SNS topic, optional ACM). Outputs feed `backend.hcl` and environment notifications/certificates.
- `environments/dev/`: Dev root stack wiring modules together, plus environment-specific tfvars/backends and stack tests.
- `environments/prod/`: Prod root stack with the same module wiring as dev, but stricter defaults for resilience and protection.
- `modules/`: Focused building blocks with single responsibilities.
- `modules/alb`: Internet-facing ALB, listeners, target group, and edge SG rules.
- `modules/budget`: Monthly budget with warning/critical thresholds and notifications.
- `modules/ecs`: ECS cluster, task definition, service, IAM, and logs for Fargate/EC2 modes.
- `modules/ecs-ec2-capacity`: ECS EC2 capacity provider backed by an Auto Scaling group.
- `modules/ecr`: ECR repository for application images, scanning, and lifecycle policy.
- `modules/eks`: EKS cluster, managed node group, and admin runner for SSM-based access.
- `modules/k8s-ec2-infra`: Self-managed Kubernetes on EC2 (control plane + workers, IAM, KMS, SGs).
- `modules/network`: VPC, subnets, routing, NAT gateways, VPC endpoints, and optional flow logs.
- `modules/observability`: Baseline CloudWatch alarms + dashboard for ALB, ECS/EC2, and RDS.
- `modules/rds`: Encrypted PostgreSQL instance, subnet group, KMS key, and SG rules.
- `docs/`: Architecture, decisions, runbook, FinOps guidance, and test strategy.
- `tests/terraform/`: Terraform test suites covering selectors and module behavior without a live backend.
- `k8s/`: Demo manifests (Kustomize base + overlays) for the Kubernetes options.
- `scripts/`: CI helpers (FinOps summary).

## Environment Model
Dev and prod are separate root stacks with environment-scoped configuration files.
Defaults in tfvars reinforce cost and safety posture differences:
- Dev emphasizes cost optimization (Fargate Spot default, single NAT gateway, HTTP listener allowed, shorter log retention, alarms optional).
- Prod favors stability (Fargate default, multi-NAT, Multi-AZ RDS, deletion protection + final snapshot, alarms enforced, `prevent_destroy = true`).
- Interface VPC endpoints and VPC Flow Logs are enabled by default in prod and opt-in in dev.

## Selectors and Modes
Platform selection is a single variable shared by both environments:
- Allowed values: `ecs`, `k8s_self_managed`, `eks`.
- Defaults: `ecs` in both environment tfvars.
- One active platform per environment; ECS and Kubernetes modules are mutually exclusive by design.

ECS capacity modes are another guarded selector:
- `ecs_capacity_mode`: `fargate`, `fargate_spot`, or `ec2`.
- Fargate Spot in prod requires `allow_spot_in_prod = true`.

## Portfolio Commit Workflow
This repo is used as a portfolio artifact, so commit history matters as much as the code.
When curating or rebuilding history, follow these defaults:
- Use 8–12 milestone commits with Conventional Commit messages.
- Keep commits coherent and ordered; each commit should be buildable when feasible.
- Prefer folder-based staging; use `git add -p` only when a file mixes concerns.
- Run relevant Makefile checks before each commit (fmt/validate/lint/docs-check/test).
- Do not commit real account IDs, ARNs, state, or secrets; the placeholder tfvars/backends are safe to keep.

## How to Navigate and Run
- Format: `make fmt`
- Format (check): `make fmt-check`
- Validate (backendless init): `make validate`
- Lint: `make lint`
- Security scan: `make security`
- Docs generation/check: `make docs`, `make docs-check`
- Cost estimate: `make cost`
- Tests: `make test`
- Plan dev: `make plan ENV=dev platform=ecs`
- Apply dev: `make apply ENV=dev platform=ecs`
- Plan prod: `make plan ENV=prod platform=ecs`
- Apply prod: `make apply ENV=prod platform=ecs`

The plan/apply workflow expects bootstrap outputs to be wired into each environment backend config and tfvars before running.
