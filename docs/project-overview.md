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
├── Makefile
├── bootstrap
│   ├── README.md
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── versions.tf
│   ├── provider.tf
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
│   │   ├── stack.tftest.hcl
│   │   └── infracost.tfvars
│   └── prod
│       ├── backend.tf
│       ├── backend.hcl
│       ├── backend.hcl.example
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── versions.tf
│       ├── stack.tftest.hcl
│       └── infracost.tfvars
├── modules
│   ├── alb
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── versions.tf
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
│   │   └── README.md
│   └── rds
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── versions.tf
│       ├── rds.tftest.hcl
│       └── README.md
├── docs
│   ├── architecture.md
│   ├── architecture.mmd
│   ├── decisions.md
│   ├── finops.md
│   ├── costs.md
│   ├── runbook.md
│   ├── tests.md
│   ├── well-architected.md
│   ├── README.md
│   └── project-overview.md
├── tests
│   └── terraform
│       ├── main.tf
│       ├── platform.tftest.hcl
│       ├── compute_mode.tftest.hcl
│       └── network.tftest.hcl
├── k8s
│   ├── namespace.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   └── ingress.yaml
├── .github
│   └── workflows
│       └── ci.yml
├── infracost.yml
├── infracost-usage-bootstrap.yml
├── infracost-usage-dev.yml
├── infracost-usage-prod.yml
└── scripts
    └── finops-ci.sh
```

Note: local state, lockfiles, generated caches, and environment-specific values are excluded (for example: `.terraform/`, `.infracost/`, `terraform.tfstate*`, and `terraform.tfvars`). Non-infra docs like interview notes or social drafts are also omitted for focus.

## Key Directories and Responsibilities
- `bootstrap/`: One-time/account prerequisites (state bucket + logging bucket, KMS key, SNS topic, optional ACM). Outputs feed `backend.hcl` and environment notifications/certificates.
- `environments/dev/`: Dev root stack wiring modules together, plus environment-specific tfvars/backends and stack tests.
- `environments/prod/`: Prod root stack with the same module wiring as dev, but stricter defaults for resilience and protection.
- `modules/`: Focused building blocks with single responsibilities.
- `modules/alb`: Internet-facing ALB, listeners, target group, and edge SG rules.
- `modules/budget`: Monthly budget with warning/critical thresholds and notifications.
- `modules/ecs`: ECS cluster, task definition, service, IAM, and logs for Fargate/EC2 modes.
- `modules/ecs-ec2-capacity`: ECS EC2 capacity provider backed by an Auto Scaling group.
- `modules/k8s-ec2-infra`: Self-managed Kubernetes on EC2 (control plane + workers, IAM, KMS, SGs).
- `modules/network`: VPC, subnets, routing, NAT gateways, and optional flow logs.
- `modules/observability`: Baseline CloudWatch alarms for ALB, ECS/EC2, and RDS.
- `modules/rds`: Encrypted PostgreSQL instance, subnet group, KMS key, and SG rules.
- `docs/`: Architecture, decisions, runbook, FinOps guidance, and test strategy.
- `tests/terraform/`: Terraform test suites covering selectors and module behavior without a live backend.
- `k8s/`: Demo manifests for the self-managed Kubernetes option.

## Environment Model
Dev and prod are separate root stacks with environment-scoped configuration files.
Defaults in tfvars reinforce cost and safety posture differences:
- Dev emphasizes cost optimization (spot-capable ECS, single NAT gateway, HTTP listener allowed, shorter retention).
- Prod favors stability (on-demand ECS by default, multi-AZ RDS, deletion protection, prevent_destroy).

Platform selection is a single variable shared by both environments:
- Defined in `environments/dev/variables.tf` and `environments/prod/variables.tf`.
- Allowed values: `ecs`, `k8s_self_managed`, `eks` (reserved and blocked by preconditions).
- Defaults: `ecs` in both environment tfvars.
- One active platform per environment; ECS and K8s modules are mutually exclusive by design.

## How to Navigate and Run
- Format: `make fmt`
- Validate (backendless init): `make validate`
- Lint: `make lint`
- Tests: `make test`
- Plan dev (requires populated `backend.hcl`): `make plan ENV=dev platform=ecs`
- Plan prod (requires populated `backend.hcl`): `make plan ENV=prod platform=ecs`

The plan/apply workflow expects bootstrap outputs to be wired into each environment backend config and tfvars before running.
