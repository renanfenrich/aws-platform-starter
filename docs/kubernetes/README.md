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

- Kustomize overlays under `k8s/overlays/*` are the default validation targets.
- If no overlays exist, all detected Kustomize roots are checked.
- Helm charts are checked when a `Chart.yaml` exists.

## Tooling prerequisites

These are CLI tools, not cluster dependencies:

- `kubectl` (for `kubectl kustomize`) or `kustomize`
- `yamllint`
- `kubeconform`
- `conftest`

Optional: add Trivy (or another config scanner) if you want a separate security scanner beyond Conftest policy rules.

See `policy/kubernetes/README.md` for rule details and exception labels.
