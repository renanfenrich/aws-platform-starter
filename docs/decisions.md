# Decisions

1) **Two-AZ baseline**
   - Improves availability while keeping the footprint minimal.

2) **ECS Fargate over EC2**
   - Removes cluster management overhead and aligns with least-ops baseline.

3) **RDS managed master password**
   - Avoids storing plaintext credentials in Terraform state.

4) **Remote state with S3 + DynamoDB**
   - Standard production pattern for locking and state durability.

5) **Single NAT in dev, multi-NAT in prod**
   - Balances cost savings in dev with resilience in production.

6) **Optional HTTP only in dev**
   - Enforces HTTPS in production while allowing quick dev iteration.

7) **Default tagging across all resources**
   - Ensures cost allocation, ownership, and environment tracing via `default_tags`.
