# Interview Talk Track - Project 1: AWS Production Platform Terraform

## Recruiter summary
- Built a production-grade AWS platform scaffold in Terraform, optimized for clarity, security, and operational readiness.
- Delivered reusable modules (network, ALB, ECS Fargate, RDS, observability) plus dev/prod environments and remote state bootstrap.
- Added CI quality gates (fmt, validate, tflint, tfsec, terraform-docs, terraform test) and documentation (architecture, runbook, decisions, costs).
- Focused on senior trade-offs: cost vs resilience, security defaults, and minimal moving parts.

## Technical overview
- Remote state bootstrap creates S3 and DynamoDB with encryption, versioning, and deletion protection.
- Environments (dev/prod) compose modules with default tagging and variable validations.
- Network module provisions a two-AZ VPC, public/private subnets, IGW, NAT, and optional flow logs.
- ALB module provides an HTTPS listener (HTTP optional for dev), restrictive security group rules, and target group health checks.
- ECS module runs Fargate tasks in private subnets with least-privilege IAM, Secrets Manager access, and CloudWatch logs.
- RDS module deploys encrypted PostgreSQL with a managed master password and KMS.
- Observability module adds CloudWatch alarms for ALB 5xx, ECS CPU, and RDS CPU.

## Key decisions and trade-offs
- Fargate over EC2 to minimize ops overhead while keeping scaling options open.
- Two AZs as a baseline for availability; single NAT in dev to reduce cost.
- HTTPS enforced by default; HTTP only allowed in dev for speed.
- Managed RDS master password avoids secrets in Terraform state.
- Minimal alarms to avoid noise; leaves room for app-specific dashboards later.

## Failure scenarios
- ALB 5xx spike: check target health, ECS logs, and recent deploys; roll back via Terraform or image tag.
- ECS CPU saturation: increase task size or desired count; add autoscaling if needed.
- RDS CPU or storage pressure: scale instance class or storage; review queries and connections.
- NAT outage (dev single NAT): accept reduced resilience; for prod use multi-NAT.
- State lock contention: verify DynamoDB lock table and team workflow; use force unlock only with coordination.

## What was intentionally not built
- WAF, IDS/IPS, or advanced edge security controls.
- Blue/green deployments or ECS autoscaling policies.
- Centralized logging or metrics stack beyond baseline CloudWatch alarms.
- VPC endpoints, private registries, or multi-account orchestration.

## Well-Architected alignment
- Operational Excellence: IaC, runbook, and CI checks.
- Security: private subnets, TLS by default, KMS encryption, Secrets Manager.
- Reliability: multi-AZ architecture, remote state locking, health checks.
- Performance Efficiency: right-sized Fargate tasks and ALB health checks.
- Cost Optimization: single NAT in dev, size defaults, configurable log retention.
- Sustainability: smaller dev defaults with clear scaling knobs.

## Common interview questions
- "Why Fargate?" -> Reduced ops burden, quick scaling, strong baseline security without cluster management.
- "How do you keep secrets out of state?" -> Use RDS managed passwords and pass Secrets Manager ARNs to ECS.
- "How would you harden this for production?" -> Add WAF, access logs, VPC endpoints, backup policies, and tighter ingress.
- "What would you add for scale?" -> ECS autoscaling, ALB target tracking, and DB read replicas if required.
