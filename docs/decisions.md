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
