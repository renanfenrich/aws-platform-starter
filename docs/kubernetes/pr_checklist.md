# Kubernetes PR Checklist

- [ ] Change is scoped to a single app or environment overlay.
- [ ] All resources include required labels (`app.kubernetes.io/*`, `environment`, `owner`).
- [ ] Deployments/StatefulSets/DaemonSets have liveness + readiness probes.
- [ ] CPU/memory requests and limits are set for every container.
- [ ] Pod security context is non-root and drops all capabilities by default.
- [ ] Service accounts are least-privilege and `automountServiceAccountToken` is off unless needed.
- [ ] NetworkPolicy changes keep default-deny and document new egress/ingress.
- [ ] No plaintext secrets in git; encrypted workflow or external store is documented.
- [ ] Overlay-specific values are in `k8s/overlays/*` with minimal base changes.
- [ ] `make k8s-validate`, `make k8s-lint`, and `make k8s-policy` pass.
- [ ] Any policy exception has a documented justification in the PR description.
