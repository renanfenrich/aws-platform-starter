# Security Policy

## Reporting

If you discover a security issue, please open a private security advisory or contact the repository owner directly. Do not disclose publicly until a fix is available.

## Security Assumptions

- AWS credentials are provided via environment variables, SSO, or profiles. No static credentials are stored in this repository.
- Secrets are managed by AWS Secrets Manager and are never output in plaintext.
- RDS storage is encrypted with KMS, and the master password is managed by AWS.
- ALB ingress is restricted to HTTPS by default; HTTP is only enabled for dev.
- No public SSH is configured; EC2 access is intended through SSM Session Manager.

## Shared Responsibility

- The Terraform code provides infrastructure controls, but workload security (container image hardening, application patching, WAF rules, IDS) remains the operator’s responsibility.
- Review IAM policies before extending permissions in production.
- Monitor CloudWatch alarms and implement an incident response process.

## Data Handling

- Do not store sensitive data in tfvars or outputs.
- Use Secrets Manager ARNs for application secrets, and grant least-privilege access.

## Recommended Hardening

- In dev, enable ALB access logs and VPC flow logs when you need request-level or network visibility.
- In dev, consider interface VPC endpoints to keep ECR/SSM/Logs traffic inside the VPC.
- Add AWS Backup policies for RDS in production if required by policy.
- Add managed WAF rules, centralized log storage, and threat detection for broader security coverage.
