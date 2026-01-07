# Security Policy

## Reporting

If you discover a security issue, please open a private security advisory or contact the repository owner directly. Do not disclose publicly until a fix is available.

## Security Assumptions

- AWS credentials are provided via environment variables, SSO, or profiles. No static credentials are stored in this repository.
- Secrets are managed by AWS Secrets Manager and are never output in plaintext.
- RDS storage is encrypted with KMS, and the master password is managed by AWS.
- ALB ingress is restricted to HTTPS by default; HTTP is only enabled for dev.

## Shared Responsibility

- The Terraform code provides infrastructure controls, but workload security (container image hardening, application patching, WAF, IDS) remains the operator’s responsibility.
- Review IAM policies before extending permissions in production.
- Monitor CloudWatch alarms and implement an incident response process.

## Data Handling

- Do not store sensitive data in tfvars or outputs.
- Use Secrets Manager ARNs for application secrets, and grant least-privilege access.

## Recommended Hardening

- Enable ALB access logs and centralize log storage.
- Add VPC endpoints to reduce NAT usage and restrict egress.
- Add AWS Backup policies for RDS in production.
