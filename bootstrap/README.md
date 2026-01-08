# Bootstrap State

I keep remote state separate to avoid circular dependencies. This folder creates the S3 bucket and DynamoDB table used for Terraform state and locking.

## Usage

1) Initialize and apply:

```bash
terraform init
terraform apply \
  -var="aws_region=us-east-1" \
  -var="state_bucket_name=your-terraform-state" \
  -var="lock_table_name=your-terraform-locks"
```

2) Update `environments/dev/backend.hcl` and `environments/prod/backend.hcl` with the bucket and table names.

## Notes

- The state bucket has versioning, CMK encryption, access logging, and public access blocking enabled.
- The lock table has CMK encryption and point-in-time recovery enabled.
- `prevent_destroy` defaults to true to protect state assets.
- Access logs go to `${state_bucket_name}-logs` unless `log_bucket_name` is set.
- The log bucket does not log itself to avoid recursive logging.
