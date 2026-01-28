# Kubernetes Skillbook (Repo-Local)

This is the repo-local standard for Kubernetes manifests and Kustomize overlays. It is intentionally small and strict so review time stays short and failures are obvious.

## Repository conventions

### Layout
- Manifests live in `k8s/` and use Kustomize (`k8s/base` + `k8s/overlays/*`).
- Overlays (`k8s/overlays/dev`, `k8s/overlays/prod`) are the deployment units. Base is a shared building block.
- If Helm is introduced later, keep charts under a dedicated `charts/` directory and update the docs + policies.

### Naming
- Namespaces: short, product-focused (example: `demo`).
- Releases/instances: use the app name (`demo-app`) unless a single namespace hosts multiple instances.
- Environment labels: `dev`, `prod`, `dr` only.

### Labels and annotations (required)
Use these labels on all resources created in a deployment overlay:
- `app.kubernetes.io/name`
- `app.kubernetes.io/instance`
- `app.kubernetes.io/part-of`
- `environment`
- `owner`

Optional but recommended:
- `app.kubernetes.io/version`
- `app.kubernetes.io/component`
- `app.kubernetes.io/managed-by` (when using Helm/GitOps)

## Workload standards

### Deployments / StatefulSets / DaemonSets
- **Probes**: liveness + readiness are required for long-running workloads. Add startup probes when cold starts are expected.
- **Resources**: every container must set requests + limits for CPU and memory.
- **Security**: run as non-root, drop all capabilities by default, and prefer `RuntimeDefault` seccomp.
- **Service accounts**: disable token automount unless the pod needs it. Keep RBAC minimal and scoped.

### Jobs / CronJobs
- Prefer Jobs for one-off or batch work; CronJobs for scheduled runs.
- Set `backoffLimit`, `ttlSecondsAfterFinished`, and resources.
- If a job needs network access, add explicit NetworkPolicy egress rules.

### PDB, HPA, VPA stance
- **PDB**: required for prod, optional for dev. Keep PDBs aligned with `replicas` and HPA min values.
- **HPA**: optional, but if enabled keep the min/max aligned with env defaults.
- **VPA**: not used in this repo (too many moving parts for a small stack). If you add it, document the trade-offs in `docs/decisions.md`.

## Networking standards

### Ingress
- Assume `ingress-nginx` behind the ALB NodePort (per `k8s/README.md`).
- Use `Ingress` for HTTP routing; keep service type `ClusterIP`.

### Service types
- Allowed: `ClusterIP` (default), `NodePort` for the ingress controller only.
- `LoadBalancer` is disallowed unless an explicit policy exception is added.

### NetworkPolicy
- Default-deny is the baseline. Add allow rules for DNS, ingress controller, and explicit egress targets.
- Keep selectors tight and avoid wildcard CIDRs unless the dependency is truly external.

## Configuration and secrets

- ConfigMaps are for non-sensitive config only.
- No plaintext secrets in git. Use AWS Secrets Manager or SSM Parameter Store and inject at deploy time.
- If you introduce an encrypted-secrets workflow (SOPS, SealedSecrets, External Secrets), document it in `docs/decisions.md` and add the policy exception label described in `policy/kubernetes/README.md`.

## Helm standards (if Helm is introduced)

- Chart layout: `Chart.yaml`, `values.yaml`, `templates/`, `_helpers.tpl`.
- Required values should be explicit; avoid implicit defaults for security-critical fields.
- Keep environment-specific values in separate files (`values-dev.yaml`, `values-prod.yaml`) and document the precedence.
- Run `helm lint` and `helm template` as part of checks.

## GitOps and promotion

- PRs update overlays; overlays are the promotion units.
- Promote dev → prod by reusing the same change and adjusting only env-specific values.
- Drift detection is manual: compare `kubectl kustomize` output to live state before prod applies.

## Observability standards

- Metrics: add scrape annotations only when the app exposes a stable endpoint.
- Logs: emit structured logs and include request IDs/correlation IDs where possible.
- Alerts: ownership belongs to the app owner; infra alerts remain minimal.

## Decision matrices

### Workload kind selection

| Workload | Use when | Avoid when |
| --- | --- | --- |
| Deployment | Stateless service with rolling updates | Needs stable IDs or persistent volume identity |
| StatefulSet | Ordered rollout, stable network IDs, persistent volumes | Simple stateless workloads |
| Job | One-off batch task | Needs scheduling or repeated runs |
| CronJob | Scheduled batch task | Long-running service |

### Service exposure

| Service type | Use when | Guardrail |
| --- | --- | --- |
| ClusterIP | Default for app services | Always pair with Ingress when HTTP |
| NodePort | Ingress controller only | Restrict security groups/NLB/ALB to known CIDRs |
| LoadBalancer | Only when explicitly approved | Requires policy exception label |

## DO / DON'T

**DO**
- Keep overlays as the deployable unit.
- Keep manifests small and explicit.
- Add resource requests/limits and probes by default.
- Use least-privilege service accounts.
- Update policies and docs with any new patterns.

**DON'T**
- Ship plaintext secrets.
- Add public SSH or privileged pods without written justification.
- Introduce Helm without a documented migration path.

## PR checklist

Use `docs/kubernetes/pr_checklist.md` for reviews.
