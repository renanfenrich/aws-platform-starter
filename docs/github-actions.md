# GitHub Actions Setup

This repo uses GitHub Actions for CI. The main `terraform` job always runs; the `infracost` job runs on pull requests only when its required secrets are present.

## Repository Settings

- Enable Actions (Settings -> Actions -> General).
- Workflow permissions: `Read and write`. The workflow posts PR comments and uploads artifacts, so the default `GITHUB_TOKEN` needs write access.
- If your org restricts actions, allow the actions used in `.github/workflows/ci.yml`.

## Required Secrets

Set these as repo or org secrets:

- `INFRACOST_API_KEY`: required to run the Infracost job.
- One of:
  - `AWS_ROLE_ARN` (recommended, OIDC), or
  - `AWS_ACCESS_KEY_ID` + `AWS_SECRET_ACCESS_KEY` (fallback).

If `INFRACOST_API_KEY` is missing, or AWS credentials are not set, the Infracost job is skipped. The rest of CI still runs.

## AWS OIDC Role (Recommended)

Create an IAM OIDC provider for `token.actions.githubusercontent.com` with audience `sts.amazonaws.com`, then create a role that GitHub Actions can assume and attach a read-only policy appropriate for cost estimation.

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
