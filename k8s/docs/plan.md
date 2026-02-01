# K8s expansion plan

This plan expands `k8s/` into a production-grade layout with minimal churn. It does not change application code and keeps Kustomize as the default for app overlays; Helm is reserved for third-party platform charts.

## Current state (inventory)

- `k8s/` currently contains:
  - `base/` (shared resources for the demo app)
  - `overlays/dev` and `overlays/prod`
  - `kind-config.yaml`
  - `README.md`
- Deployment approach: Kustomize base + overlays, applied with `kubectl apply -k`. There are no Helm charts or GitOps controllers in this repo today.
- CI checks already exist:
  - Local/CI entrypoint: `scripts/kubernetes/run_checks.sh` (Makefile targets `k8s-validate`, `k8s-lint`, `k8s-policy`, `k8s-sec`).
  - GitHub Actions: `.github/workflows/kubernetes-ci.yml` installs `yamllint`, `kubeconform`, and `conftest` and runs the make targets. Helm checks run only when a `Chart.yaml` is present.

## Target structure (proposed)

```
k8s/
  README.md
  kind-config.yaml
  clusters/
    dev/
      kustomization.yaml
    prod/
      kustomization.yaml
  apps/
    demo-app/
      base/
        kustomization.yaml
        deployment.yaml
        service.yaml
        ingress.yaml
        hpa.yaml
        pdb.yaml
        configmap.yaml
        serviceaccount.yaml
        networkpolicy-*.yaml
        secret-template.yaml
      overlays/
        dev/
          kustomization.yaml
          patch-deployment.yaml
          patch-hpa.yaml
        prod/
          kustomization.yaml
          patch-deployment.yaml
          patch-hpa.yaml
          patch-pdb.json
  platform/
    namespaces/
      base/
        kustomization.yaml
        namespaces.yaml
        limitrange-apps.yaml
        resourcequota-apps.yaml
      overlays/
        dev/
          kustomization.yaml
          patch-resourcequota-apps.yaml
        prod/
          kustomization.yaml
          patch-resourcequota-apps.yaml
    ingress-nginx/
      kustomization.yaml
    cert-manager/
      kustomization.yaml
    external-dns/
      kustomization.yaml
    metrics-server/
      kustomization.yaml
    observability/
      kube-prometheus-stack/
        kustomization.yaml
      logging/
        kustomization.yaml
      tracing/
        kustomization.yaml
    secrets/
      kustomization.yaml
  policies/
    kyverno/
      base/
        kustomization.yaml
        policies.yaml
      overlays/
        dev/
          kustomization.yaml
        prod/
          kustomization.yaml
  helm/
    values/
      dev/
        ingress-nginx.yaml
        cert-manager.yaml
        external-dns.yaml
        metrics-server.yaml
        kube-prometheus-stack.yaml
        logging.yaml
        tracing.yaml
        external-secrets.yaml
      prod/
        ingress-nginx.yaml
        cert-manager.yaml
        external-dns.yaml
        metrics-server.yaml
        kube-prometheus-stack.yaml
        logging.yaml
        tracing.yaml
        external-secrets.yaml
  scripts/
    README.md
  docs/
    plan.md
    standards.md
```

Notes:
- `clusters/<env>/kustomization.yaml` becomes the single entrypoint per environment.
- `apps/<app>/base` + `apps/<app>/overlays/<env>` holds workload manifests.
- `platform/` wraps third-party charts and cluster-wide resources; Helm values live under `helm/values/<env>`.
- `policies/` houses Kyverno (or Gatekeeper) policies with env overlays.

## Mapping from current to target

| Current path | Target path | Notes |
| --- | --- | --- |
| `k8s/base/*` | `k8s/apps/demo-app/base/*` | Move as-is; update kustomization refs. |
| `k8s/overlays/dev/*` | `k8s/apps/demo-app/overlays/dev/*` | Move as-is. |
| `k8s/overlays/prod/*` | `k8s/apps/demo-app/overlays/prod/*` | Move as-is. |
| `k8s/base/namespace.yaml` | `k8s/platform/namespaces/base/namespaces.yaml` | Consolidate namespace definitions; add `apps` LimitRange + ResourceQuota. |
| `k8s/base/secret-template.yaml` | `k8s/apps/demo-app/base/secret-template.yaml` | Keep as template only; do not add to kustomization. |
| `k8s/README.md` | `k8s/README.md` | Update to use `clusters/<env>` entrypoints and reference docs. |

## Baseline checklists

The workload and platform checklists live in `k8s/docs/standards.md`. Those checklists are the acceptance bar for every workload or platform addition.

## CI quality gates for `k8s/`

Required gates (fail-fast):
- `kubectl kustomize k8s/clusters/dev` and `kubectl kustomize k8s/clusters/prod`.
- `helm lint` and `helm template` for any platform charts.
- `kubeconform` strict validation for rendered manifests (cluster version pinned via `K8S_VERSION`).
- `conftest` policy checks for `kubernetes.policy` and `kubernetes.security` namespaces.

Optional gate:
- `kube-score` for static checks (treat as required only after the baseline is clean).

File locations to update as the structure grows:
- CI workflow: `.github/workflows/kubernetes-ci.yml`
- Local/CI runner: `scripts/kubernetes/run_checks.sh`
- Policies: `policy/kubernetes/rego`
- YAML lint config: `scripts/kubernetes/yamllint.yaml`

## Execution plan (PR-sized steps)

### PR1 - Plan and standards (docs only)

Files to add/change:
- `k8s/docs/plan.md`
- `k8s/docs/standards.md`
- `k8s/README.md`

Acceptance criteria:
- Docs describe the target layout, checklists, and CI gates.
- No manifest or platform behavior changes.

Test commands:
- `make k8s-lint`

Rollback notes:
- Revert the docs if needed; no infra impact.

### PR2 - Cluster entrypoints (no resource moves)

Files to add/change:
- `k8s/clusters/dev/kustomization.yaml`
- `k8s/clusters/prod/kustomization.yaml`
- `k8s/README.md` (apply path updated)

Acceptance criteria:
- `kubectl kustomize k8s/clusters/dev` and `k8s/clusters/prod` match the existing overlay outputs.
- No manifest diffs other than new entrypoints.

Test commands:
- `make k8s-validate`

Rollback notes:
- Remove `k8s/clusters/` and keep using `k8s/overlays/*`.

### PR3 - Move demo app into `apps/`

Files to add/change:
- Move `k8s/base/*` to `k8s/apps/demo-app/base/*`.
- Move `k8s/overlays/*` to `k8s/apps/demo-app/overlays/*`.
- Update `k8s/clusters/*/kustomization.yaml` to reference the new app path.

Acceptance criteria:
- `kubectl kustomize k8s/clusters/dev` and `prod` render the same resources as before.
- Old `k8s/base` and `k8s/overlays` removed.

Test commands:
- `make k8s-validate`
- `make k8s-lint`
- `make k8s-policy`
- `make k8s-sec`

Rollback notes:
- Revert the moves and keep `k8s/base` + `k8s/overlays`.

### PR4 - Platform core (ingress, cert-manager, external-dns, metrics-server)

Files to add/change:
- `k8s/platform/ingress-nginx/*`
- `k8s/platform/cert-manager/*`
- `k8s/platform/external-dns/*`
- `k8s/platform/metrics-server/*`
- `k8s/helm/values/dev/*` and `k8s/helm/values/prod/*`
- `k8s/clusters/*/kustomization.yaml` (include platform components)

Acceptance criteria:
- Platform components render cleanly for both envs.
- No secrets are committed; chart values only.

Test commands:
- `make k8s-validate`
- `make k8s-lint`
- `make k8s-policy`
- `make k8s-sec`

Rollback notes:
- Remove platform components from cluster kustomizations.

### PR5 - Observability stack (metrics, logs, traces)

Files to add/change:
- `k8s/platform/observability/kube-prometheus-stack/*`
- `k8s/platform/observability/logging/*`
- `k8s/platform/observability/tracing/*`
- `k8s/helm/values/dev/*` and `k8s/helm/values/prod/*`

Acceptance criteria:
- Observability charts render for both envs.
- Defaults are minimal and cost-aware in dev.

Test commands:
- `make k8s-validate`
- `make k8s-lint`
- `make k8s-policy`
- `make k8s-sec`

Rollback notes:
- Remove observability components from cluster kustomizations.

### PR6 - Policies, namespaces, and CI targeting

Files to add/change:
- `k8s/platform/namespaces/*` (Namespace + LimitRange + ResourceQuota).
- `k8s/policies/kyverno/*` (or Gatekeeper, but pick one).
- `scripts/kubernetes/run_checks.sh` (ensure `k8s/clusters/*` are validated targets).
- `.github/workflows/kubernetes-ci.yml` (only if new tooling is required).

Acceptance criteria:
- Namespaces enforce quotas/limits.
- Policies render cleanly and do not block the current demo app.
- CI validates `k8s/clusters/*` as the primary entrypoints.

Test commands:
- `make k8s-validate`
- `make k8s-policy`
- `make k8s-sec`

Rollback notes:
- Remove policy and namespace layers from cluster kustomizations and revert CI updates.
