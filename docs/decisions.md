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

5) **Remote state with S3 + DynamoDB**
   - This is the standard pattern for teams and it prevents concurrent apply issues. Even a small repo benefits from state locking.

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
   - State buckets and lock tables enforce `prevent_destroy`; tearing them down requires an explicit config change.

17) **Name prefix length guard**
   - `project_name` plus `environment` must fit the ALB and target group 32-character limits; tags carry the remaining context.
