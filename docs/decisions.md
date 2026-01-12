# Decisions

These are the defaults I chose for this repo. Each one is a trade-off, and I kept them explicit on purpose.

1) **Two-AZ baseline**
   - I default to two AZs because it avoids the single-AZ failure mode without adding much complexity.

2) **ECS capacity providers with Fargate default**
   - Fargate stays the prod default and dev uses Fargate Spot with Fargate fallback; `ecs_capacity_mode` lets you switch to an EC2 capacity provider when host-level control is required.

3) **EC2 capacity provider uses ASG + Launch Template with SSM**
   - EC2 capacity uses a private Auto Scaling group and SSM-enabled instance role. SSH is not opened by default; access is intended through SSM.

4) **RDS managed master password**
   - I do not want database credentials in Terraform state. RDS manages the master password and stores it in Secrets Manager.

5) **Remote state with S3 native locking**
   - Terraform 1.6+ supports S3 lock files, so I avoid a separate DynamoDB table while still preventing concurrent applies.

6) **CMK encryption + access logs for state storage**
   - State storage uses a customer-managed KMS key and S3 access logs. The log bucket does not log itself to avoid recursive logging.

7) **Single NAT in dev, multi-NAT in prod**
   - NAT gateways are expensive. Dev uses one to save cost; prod uses one per AZ to avoid a single point of failure for outbound traffic.

8) **Optional HTTP only in dev**
   - I enforce HTTPS by default. HTTP is only there for quick dev testing when needed.

9) **Default tagging across all resources**
   - I rely on `default_tags` so ownership and environment context are always present without repeating tags in every module.

10) **Platform selector with ECS default**
   - `platform` allows `ecs` or `k8s_self_managed` today, with `eks` reserved for future work. ECS remains the default to preserve existing behavior.

11) **Self-managed Kubernetes via kubeadm**
   - The Kubernetes option uses a single control plane instance and a worker Auto Scaling group. It is deliberately simple and non-HA, which keeps the repo deterministic and easy to reason about.

12) **Join command stored in SSM Parameter Store**
   - The control plane writes a kubeadm join command to SSM (encrypted with a CMK). Workers read it at boot, avoiding public SSH and keeping the join flow mostly automated.

13) **Ingress behind the existing ALB**
   - Ingress traffic stays on the existing ALB. The ALB forwards to a fixed NodePort on worker nodes, keeping the edge consistent across ECS and Kubernetes.

14) **Bootstrap now includes SNS notifications**
   - The bootstrap stack creates a single SNS topic for infrastructure alarms and reuses the bootstrap KMS key for encryption. Alarms only notify when the ARN is explicitly wired into each environment.

15) **ACM is opt-in with DNS validation only**
   - Certificates are created only when a hosted zone ID is provided. Route53 hosted zones are out of scope for this repo to avoid accidental DNS ownership changes.

16) **Bootstrap state resources are protected by default**
   - State buckets enforce `prevent_destroy`; tearing them down requires an explicit config change.

17) **Name prefix length guard**
   - `project_name` plus `environment` must fit the ALB and target group 32-character limits; tags carry the remaining context.

18) **FinOps posture per environment**
   - Dev is explicitly `cost_optimized` with spot-first defaults; prod is `stability_first` and requires an opt-in to use Fargate Spot.

19) **Deploy-time cost enforcement**
   - Deploys require an `estimated_monthly_cost` input and are blocked when the estimate exceeds the hard budget threshold.

20) **Mandatory cost allocation tags + environment budgets**
   - Tagging is enforced across modules, and budgets are scoped by the `Environment` cost allocation tag to keep dev/prod spend distinct.

21) **ALB access logs are a prod default**
   - Access logs provide request-level visibility and are cheap enough to justify in prod.
   - Logs land in a dedicated S3 bucket with lifecycle rules; the policy limits writes to the ALB log delivery service and can be narrowed to explicit ALB ARNs.

22) **VPC Flow Logs are prod-default, dev opt-in**
   - Flow logs are valuable for prod troubleshooting but noisy and costlier in dev, so dev stays off unless explicitly enabled.

23) **WAF is optional and attach-only**
   - WAF rules are application-specific. This repo only supports attaching an existing Web ACL when enabled and keeps it off by default.

24) **Hardening stops at baseline visibility**
   - I stop at access logs, flow logs, and optional WAF attachment to keep scope tight; managed rule sets and centralized logging pipelines belong in a larger platform.

25) **ECR repository per environment with AWS-managed encryption**
   - I add a single ECR repo per environment so images live with the stack and IAM can stay scoped.
   - I use AES256 (AWS-managed) to keep the baseline simple; a CMK can be added later if policy requires it.
