# Upgrade Audit Report

**Date:** 2026-02-02
**Mode:** audit-and-upgrade
**Status:** analysis-only, no changes applied

---

## Phase 1 – Inventory

### Terraform & Providers

| Item | Current version / constraint | Evidence |
|---|---|---|
| Terraform CLI (root stacks, bootstrap, example, k8s module) | >= 1.11.0 | versions.tf (multiple) |
| Terraform CLI (CI) | 1.11.0 | ci.yml, terraform-ci.yml |
| AWS provider (root stacks / tests / examples) | ~> 5.0 | versions.tf, main.tf |
| AWS provider (modules) | >= 5.0 | versions.tf |
| Archive provider | >= 2.4 | versions.tf |
| Provider lock file | none | no terraform.lock.hcl present |

### CI & Tooling

| Item | Current version / constraint | Evidence |
|---|---|---|
| GitHub Actions runner | ubuntu-latest (floating) | *.yml |
| actions/checkout | v4 | *.yml |
| hashicorp/setup-terraform | v3 | ci.yml, terraform-ci.yml |
| terraform-linters/setup-tflint | v4 | ci.yml, terraform-ci.yml |
| TFLint CLI | v0.53.0 | ci.yml, terraform-ci.yml |
| tflint-ruleset-aws | 0.34.0 | .tflint.hcl |
| tfsec action | v1.0.3 | ci.yml |
| terraform-docs | v0.17.0 | ci.yml |
| Infracost CLI | install script (unpinned) | ci.yml |
| Infracost GH action | infracost/infracost-gh-action@v2 | ci.yml |
| actions/setup-python | v5 (Python 3.11) | kubernetes-ci.yml |
| actions/setup-go | v5 (Go 1.22.6) | kubernetes-ci.yml |
| azure/setup-kubectl | v4 (kubectl v1.29.2) | kubernetes-ci.yml |
| dorny/paths-filter | v3 | kubernetes-ci.yml |
| actions/upload-artifact | v4 | ci.yml, terraform-ci.yml |
| Mermaid CLI | @mermaid-js/mermaid-cli@10.9.1 | Makefile |

### Kubernetes Toolchain

| Item | Current version / constraint | Evidence |
|---|---|---|
| kubectl | v1.29.2 | kubernetes-ci.yml |
| K8S_VERSION (kubeconform) | 1.29.2 | run_checks.sh |
| kubeconform | v0.6.4 | kubernetes-ci.yml |
| conftest | v0.45.0 | kubernetes-ci.yml |
| yamllint | unpinned (pip install) | kubernetes-ci.yml |
| helm | required if charts exist (unpinned) | run_checks.sh |
| kustomize | via kubectl kustomize (unpinned) | run_checks.sh, README.md |
| OPA policy target | OPA 1.x / Rego v1 | README.md |

### Runtime / Operational CLIs

| Item | Current version / constraint | Evidence |
|---|---|---|
| AWS CLI | required, unpinned | dr-readiness.sh, runbook.md |
| Docker CLI | required, unpinned | runbook.md |
| jq | required, unpinned | terraform-ci.yml, finops-ci.sh |
| Node.js | required for mermaid-cli (unpinned) | Makefile (npx usage) |
| Python | required for scripts, CI | dr-readiness.sh, kubernetes-ci.yml |
| Go | required for kubeconform / conftest installs | kubernetes-ci.yml |

### Container Images & Add-ons

| Item | Current tag | Evidence |
|---|---|---|
| Argo CD | quay.io/argoproj/argocd:v3.2.2 | install.yaml |
| Dex | ghcr.io/dexidp/dex:v2.43.0 | install.yaml |
| Redis | redis:8.2.2-alpine | install.yaml |
| Reference app | nginxinc/nginx-unprivileged:stable-alpine | deployment.yaml |
| Test container image | public.ecr.aws/nginx/nginx:latest | main.tf |
| Ingress-NGINX | controller-v1.10.1 (URL-applied) | runbook.md |
| Placeholders | REPLACE_WITH_ECR_IMAGE* | deployment.yaml, patch-deployment.yaml |

---

## Phase 2 – Latest Stable Baseline

| Item | Latest stable version | Release date | Status / notes |
|---|---|---|---|
| Terraform CLI | 1.14.4 | 2026-01-28 | Current stable v1 |
| AWS provider | 6.27.0 | 2026-01-26 | Major upgrade from 5.x |
| Archive provider | 2.7.1 | 2025-05-12 | Current stable |
| terraform-docs | 0.20.0 | 2025-09-19 | Current stable |
| TFLint | 0.60.0 | 2025-11-16 | Current stable |
| tflint-ruleset-aws | 0.44.0 | 2025-11-01 | Current stable |
| tfsec | 1.28.14 | 2025-05-02 | Superseded by Trivy |
| Infracost CLI | 0.10.42 | 2025-07-07 | Current stable |
| Infracost GH action (new) | infracost/actions@v3.0.1 | 2024-08-07 | Replacement |
| Infracost GH action (old) | v0.8.4 | 2021-11-10 | Deprecated |
| Kubernetes | 1.35.0 | 2025-12-10 | Current stable |
| Docker Engine | 29.1.3 | 2025-12-12 | Current stable |
| Docker Compose | 5.0.1 | 2025-12-18 | Current stable |
| Node.js LTS | 24.13.0 | 2026-01-12 | Active LTS |
| Python | 3.14.2 | 2025-12-05 | Current stable |
| Go | 1.25.6 | 2026-01-08 | Current stable |
| Conftest | 0.64.0 | 2025-11-09 | Rego v1 default |
| Kustomize | 5.7.1 | not captured | Current stable |
| Argo CD | 3.2.2 | not captured | v3.3.0 pre-release |
| ingress-nginx controller | 1.14.1 | 2025-12-05 | Latest controller |
| AWS CLI v2 | 2.33.12 | not captured | Changelog head |

---

## Phase 3 – Compatibility & Risk Analysis

### High-risk
- AWS provider 5.x → 6.27.0: major breaking changes, production-wide blast radius.
- Kubernetes toolchain 1.29.2 → 1.35.0: API compatibility and validation risk.
- ingress-nginx 1.10.1 → 1.14.1: annotation and default changes impacting EKS ingress.
- tfsec: effectively deprecated in favor of Trivy.

### Conditional
- Terraform CLI 1.11.0 → 1.14.4: minor-version behavior shifts possible.
- Conftest 0.45.0 → 0.64.0: Rego v1 default.
- TFLint, tflint-ruleset-aws, terraform-docs: new rules and output diffs.
- Python, Go, Node: CI tooling impact.

### Safe
- Archive provider 2.4 → 2.7.1.
- Docker Engine / Compose.
- Argo CD already at latest stable.

---

## Phase 4 – Upgrade Strategy

**Order of operations (lowest risk → highest):**
1. Pin versions and add lockfiles.
2. Upgrade CI-only tooling.
3. Upgrade Terraform CLI.
4. Upgrade providers in two stages: latest 5.x, then 6.x.
5. Upgrade Kubernetes toolchain and validation.
6. Refresh add-ons and container images.
7. Upgrade runtime CLIs.

**Rollback:** tag or commit after each step.

**Validation gates:**
- Terraform: `make fmt-check`, `make validate`, `make lint`, `make security`, `make docs-check`, `make test`
- Kubernetes: `make k8s-validate`, `make k8s-lint`, `make k8s-policy`, `make k8s-sec`
- Plans: `make plan ENV=dev platform=ecs`

---

## Phase 5 – Output Artifacts

### Upgrade Matrix

| Item | Current | Latest stable | Risk | Blast radius | Breaking change summary | Required actions |
|---|---|---|---|---|---|---|
| Terraform CLI | 1.11.0 | 1.14.4 | Conditional | CI + local | Minor behavior changes | Update CI + docs |
| AWS provider | ~>5.0 | 6.27.0 | High | Infra / prod | Major breaking changes | Follow v6 guide |
| Archive provider | >=2.4 | 2.7.1 | Safe | Infra | Minor | Pin + re-init |
| terraform-docs | 0.17.0 | 0.20.0 | Conditional | Docs / CI | Output changes | Re-run docs |
| TFLint | 0.53.0 | 0.60.0 | Conditional | CI | New rules | Fix findings |
| tflint-ruleset-aws | 0.34.0 | 0.44.0 | Conditional | CI | New rules | Update plugin |
| tfsec | v1.0.3 | 1.28.14 | High | CI | Deprecated | Migrate to Trivy |
| Infracost CLI | unpinned | 0.10.42 | Conditional | CI | Output changes | Pin version |
| Infracost GH action | v2 | v3.0.1 | Conditional | CI | Repo deprecated | Migrate |
| AWS CLI | unpinned | 2.33.12 | Conditional | Ops | CLI output | Pin + validate |
| kubectl | 1.29.2 | 1.35.0 | High | CI / runtime | API skew | Plan upgrade |
| conftest | 0.45.0 | 0.64.0 | Conditional | CI | Rego v1 | Fix policies |
| ingress-nginx | 1.10.1 | 1.14.1 | High | Runtime | Controller changes | Update manifests |

---

## Change Impact Summary

- **CI:** new lint, policy, and docs failures expected.
- **Infrastructure:** AWS provider v6 and Kubernetes upgrades are highest risk.
- **Runtime:** ingress controller and image updates require controlled rollout.
- **Workflow:** local toolchain upgrades required.

---

## Verification Gaps

- Latest versions not verified: kubeconform, helm, yamllint, mermaid-cli.
- Dex, Redis, nginx-unprivileged images should be pinned to digests.
- AWS CLI release date for 2.33.12 not verified.

**No changes were applied.**
