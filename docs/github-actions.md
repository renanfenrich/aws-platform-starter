# GitHub Actions Setup

This repo uses GitHub Actions for CI. The main `terraform` job always runs; the `infracost` job runs on pull requests only when its required secrets are present.

## Repository Settings

- Enable Actions (Settings -> Actions -> General).
- Workflow permissions: `Read repository contents` is enough for the default token; the workflow explicitly requests `pull-requests: write` and `id-token: write` on the Infracost job for PR comments and OIDC. If your org restricts token scopes, allow those permissions.
- If your org restricts actions, allow the actions used in `.github/workflows/ci.yml`.

## Required Secrets

Set these as repo or org secrets:

- `INFRACOST_API_KEY`: required to run the Infracost job.
- One of:
  - `AWS_ROLE_ARN` (recommended, OIDC), or
  - `AWS_ACCESS_KEY_ID` + `AWS_SECRET_ACCESS_KEY` (fallback).

If `INFRACOST_API_KEY` is missing, or AWS credentials are not set, the Infracost job is skipped. The rest of CI still runs.

## AWS OIDC Role (Recommended)

The bootstrap stack can create the OIDC provider and role. Enable it and scope the subjects to the repo/refs you expect:

```hcl
enable_github_oidc_role    = true
github_oidc_subjects       = ["repo:OWNER/REPO:pull_request", "repo:OWNER/REPO:ref:refs/heads/main"]
github_oidc_role_policy_arns = ["arn:aws:iam::ACCOUNT_ID:policy/ci-readonly"]
```

Apply bootstrap, then set `AWS_ROLE_ARN` to the `github_oidc_role_arn` output.
If GitHub rotates certificates, update `github_oidc_thumbprints` in bootstrap.

If you cannot use bootstrap, create an IAM OIDC provider for `token.actions.githubusercontent.com` with audience `sts.amazonaws.com`, then create a role that GitHub Actions can assume and attach a least-privilege policy appropriate for cost estimation.

Example trust policy (adjust `ACCOUNT_ID`, `OWNER`, `REPO`, and branch name):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": [
            "repo:OWNER/REPO:pull_request",
            "repo:OWNER/REPO:ref:refs/heads/main"
          ]
        }
      }
    }
  ]
}
```

Set `AWS_ROLE_ARN` to the role ARN.

## Static AWS Keys (Fallback)

If you cannot use OIDC, provide `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`. Use least-privilege, rotate regularly, and treat these as scoped CI credentials only.

## Verify

Open a pull request or push to `main`. The `terraform` job should run without secrets; the `infracost` job should run only when the secrets above are present.
