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
   - `platform` allows `ecs`, `k8s_self_managed`, or `eks`. ECS remains the default to preserve existing behavior.

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
   - `project_name` plus `environment` must stay within the 28-character guard so ALB and target group names remain valid; tags carry the remaining context.

18) **FinOps posture per environment**
   - Dev is explicitly `cost_optimized` with spot-first defaults; prod is `stability_first` and requires an opt-in to use Fargate Spot.

19) **Deploy-time cost enforcement**
   - When `enforce_cost_controls` is true (default), deploys require `estimated_monthly_cost` and block when the estimate exceeds the hard budget threshold.

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

26) **Targeted VPC endpoints, not a full catalog**
   - S3 and DynamoDB gateway endpoints are always enabled because they carry the bulk of baseline service traffic and reduce NAT data processing.
   - Interface endpoints for ECR (api/dkr), CloudWatch Logs, and SSM (ssm/ssmmessages/ec2messages) are prod-default and dev opt-in to balance cost and operational clarity.
   - I am explicitly not adding STS, KMS, Secrets Manager, or CloudWatch metrics endpoints yet; their traffic profile here is smaller, and each adds policy surface and operational overhead. Revisit when usage justifies it.

27) **RDS-only data protection baseline**
   - I rely on native RDS automated backups and final snapshots for recoverability. Dev keeps short retention and skips final snapshots; prod keeps longer retention, deletion protection, and requires a final snapshot on delete.
   - AWS Backup orchestration and cross-region DR are intentionally out of scope to keep the repo small and avoid introducing a second backup control plane without a clear operational need.

28) **Kustomize-based Kubernetes demo with baseline hardening**
   - I use kustomize overlays (dev/prod) so environment differences are explicit without introducing Helm or operators.
   - The demo includes PSA restricted labels, probes, requests/limits, HPA, PDB, and default-deny network policies to show safe-by-default patterns while keeping scope tight.

29) **Minimal ECS autoscaling (CPU target tracking only)**
   - Autoscaling is opt-in and only adjusts ECS service desired count via a single CPU target tracking policy.
   - I skipped ALB request-based scaling and multi-metric/step scaling to keep behavior deterministic and testable.

30) **No distributed tracing**
   - The stack is single-hop and small; tracing adds instrumentation overhead without a clear operational payoff.
   - ALB latency, service metrics, and logs are enough until real multi-service paths exist.

31) **No centralized logging platform**
   - CloudWatch Logs per service keeps the footprint small and operationally simple.
   - Running OpenSearch/ELK is out of scope for this repo’s size and cost posture.

32) **Optional HTTP API + Lambda ingress**
   - I use API Gateway HTTP APIs instead of REST APIs because the feature set is sufficient for a single Lambda and the cost/latency profile is better.
   - Authentication is intentionally not wired by default; add a JWT or Lambda authorizer if you need it.
   - The serverless path is opt-in to keep the core ECS/Kubernetes flow unchanged; VPC-attached Lambda trades cold-start latency and NAT cost for private network access.

33) **EKS as a managed Kubernetes option**
   - I added EKS to offload control plane operations while keeping the API endpoint private by default and accessible via the SSM admin runner.
   - Ingress stays behind the existing ALB and a fixed NodePort to avoid creating a second public ALB and to keep edge behavior consistent.
   - The footprint stays minimal: only core EKS add-ons (vpc-cni, coredns, kube-proxy) and no extra controllers beyond ingress.
