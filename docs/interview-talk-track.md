# Interview Talk Track - Project 1: AWS Platform Terraform

## Recruiter summary

- I built a small, opinionated AWS platform in Terraform for a single service: VPC, ALB, compute (ECS default with Kubernetes options), ECR, and Postgres RDS.
- Dev/prod environments share the same wiring but enforce different cost postures, budgets, and deploy-time cost guards.
- A bootstrap stack owns remote state (S3 lock files), KMS, SNS notifications, ALB log storage, and optional ACM + GitHub Actions OIDC.
- CI runs fmt/validate/tflint/tfsec/terraform-docs/terraform test; Infracost is optional but integrated for FinOps reporting.
- The scope is intentionally limited so the trade-offs are explicit.

## Technical overview

- Bootstrap creates state/log buckets with KMS, an ALB log bucket, an encrypted SNS topic, optional ACM DNS validation, and optional GitHub Actions OIDC.
- Environments (dev/prod) wire modules together, enforce required tags, and validate `platform` plus cost posture rules.
- Network module provisions a two-AZ VPC, public/private subnets, IGW, NAT, optional flow logs, and VPC endpoints (S3/DynamoDB gateway plus optional ECR/Logs/SSM interface).
- ALB module provides HTTPS by default (HTTP optional in dev), target group health checks, restrictive security groups, and optional access logs/WAF.
- Compute defaults to ECS (Fargate/Fargate Spot/EC2 capacity providers) with exec and optional autoscaling; EC2 capacity uses private ASG + SSM.
- Kubernetes options: self-managed kubeadm on EC2 (single control plane + worker ASG + NodePort ingress) or EKS with a private API endpoint and an SSM admin runner.
- RDS module deploys encrypted PostgreSQL with Secrets Manager-managed master password, backups, and prod protections (Multi-AZ, deletion protection).
- ECR module provides immutable, scan-on-push repos; API Gateway + Lambda is an opt-in serverless ingress path.
- Observability module adds baseline alarms (ALB 5xx/latency/unhealthy, ECS CPU/memory/capacity, EC2 CPU, RDS CPU/free storage) and a per-env dashboard.
- FinOps integrates AWS Budgets and deploy-time `estimated_monthly_cost` enforcement with optional Infracost reporting in CI.

## Key decisions and trade-offs

- ECS is the default path for simplicity; Kubernetes (self-managed or EKS) is optional to show the operational trade-offs without changing the ALB edge model.
- Compute stays private and SSH-free; access is via SSM, and EKS uses a private endpoint with an admin runner.
- Dev optimizes cost (single NAT, Spot-first ECS); prod optimizes stability (multi-NAT, Fargate, longer log retention).
- Interface VPC endpoints are enabled by default in prod but opt-in in dev to balance hourly endpoint cost vs NAT egress.
- HTTPS is enforced; HTTP is allowed only in dev to keep iteration fast. WAF is optional but not configured by default.
- Secrets live in Secrets Manager and KMS protects state/logs/RDS; Terraform state never stores the DB password.
- Alarms and dashboards are minimal by design to avoid noise; teams are expected to add app-specific signals.
- Cost controls are explicit: budgets per environment and deploy-time enforcement against `estimated_monthly_cost`.

## Failure scenarios

- ALB 5xx/latency/unhealthy host alarms: check target group health, ECS/K8s logs, and recent deploys; roll back if needed.
- ECS desired vs running mismatch or CPU/memory alarms: adjust task size/count, verify capacity provider strategy, or enable autoscaling.
- EC2 capacity or Kubernetes node churn: inspect ASG health, SSM connectivity, and AMI updates; replace nodes if needed.
- EKS access issues: use the admin runner via SSM and verify endpoint access settings and node group capacity.
- RDS CPU or free storage alarms: scale the instance/storage and review query pressure and connection counts.
- Cost enforcement/budget alerts: update `estimated_monthly_cost` or reduce spend before re-running plan/apply.
- NAT failure in dev (single NAT): accept reduced resilience; prod uses one NAT per AZ.
- State lock contention: coordinate with the team and use `terraform force-unlock` only when necessary.

## What was intentionally not built

- WAF rule sets, IDS/IPS, or managed auth for API Gateway.
- Blue/green deployments, canaries, or multi-metric autoscaling policies.
- Centralized logging, tracing, or a full observability platform.
- Multi-account orchestration or organization-level governance.
- Cross-region DR or automated backup policies beyond RDS defaults.

## Well-Architected alignment

- Operational Excellence: modular Terraform, repeatable workflows, CI checks, and a runbook.
- Security: private subnets, no public SSH, SSM access, TLS, KMS encryption, and Secrets Manager.
- Reliability: multi-AZ networking, remote state locking, ALB health checks, and RDS backups/protection.
- Performance Efficiency: explicit task sizing and optional autoscaling; choice of ECS/EKS/K8s where needed.
- Cost Optimization: cost posture guardrails, budgets, deploy-time enforcement, and dev cost defaults.
- Sustainability: smaller dev defaults and clear right-sizing knobs.

## Common interview questions

- "Why default to ECS instead of Kubernetes?" -> It keeps ops overhead low; EKS/self-managed are there when I need K8s features.
- "How do you keep secrets out of state?" -> RDS manages the master password in Secrets Manager; Terraform only handles the ARN.
- "How do you access private compute?" -> Session Manager for ECS/EC2 nodes; EKS uses a private endpoint with an admin runner.
- "How do you keep costs in check?" -> Budgets, cost posture validation, deploy-time `estimated_monthly_cost`, and optional Infracost in CI.
- "What would you add for a real production rollout?" -> WAF rules, centralized logging/tracing, stronger autoscaling, and multi-account separation.
