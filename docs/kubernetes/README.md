# Kubernetes Skillbook

This folder is the repo-local standard for Kubernetes work in this project. It is intentionally small and opinionated so reviews stay quick and changes stay safe.

## Contents

- `skillbook.md` — standards, decision matrices, and DO/DON'T guidance.
- `pr_checklist.md` — review checklist for Kubernetes changes.
- `templates/` — minimal, repo-aligned manifests and Helm snippets.
- `policy/kubernetes/` — Conftest policy rules and exception guidance.

## Local commands

Run the full sequence (fmt → validate → lint → policy → sec):

```bash
scripts/kubernetes/run_checks.sh
```

Run a single stage:

```bash
scripts/kubernetes/run_checks.sh fmt
scripts/kubernetes/run_checks.sh validate
scripts/kubernetes/run_checks.sh lint
scripts/kubernetes/run_checks.sh policy
scripts/kubernetes/run_checks.sh sec
```

Makefile targets:

```bash
make k8s-fmt
make k8s-validate
make k8s-lint
make k8s-policy
make k8s-sec
```

## What gets checked

- Kustomize entrypoints under `k8s/clusters/*` are validated when present.
- Overlays under `k8s/overlays/*` are also validated to keep patch sets visible.
- If neither exists, all detected Kustomize roots are checked.
- Helm charts are checked when a `Chart.yaml` exists.

## Tooling prerequisites

These are CLI tools, not cluster dependencies:

- `kubectl` (includes `kubectl kustomize`; no standalone `kustomize` required)
- `yamllint`
- `kubeconform`
- `conftest`

Optional: add Trivy (or another config scanner) if you want a separate security scanner beyond Conftest policy rules.

## Policy authoring (Rego v1)

- Policies target OPA 1.x (Rego v1). CI pins `conftest` to v0.45.0 (OPA 1.x).
- Rule bodies must use `if`, and partial set rules (like `deny`) must use `contains`.
- Format policies with `conftest fmt policy/kubernetes/rego` before committing.
- Run policy checks locally with `make k8s-policy` or `scripts/kubernetes/run_checks.sh policy`.

See `policy/kubernetes/README.md` for rule details and exception labels.
