# Bootstrap State

This folder creates the S3 bucket and DynamoDB table required for Terraform remote state and locking.

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

- The bucket has versioning, encryption, and public access blocking enabled.
- `prevent_destroy` defaults to true to protect state assets.
