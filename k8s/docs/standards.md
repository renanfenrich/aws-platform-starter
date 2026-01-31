# Kubernetes standards

This document defines the workload and platform baseline for everything under `k8s/`. It is intentionally opinionated so reviews stay fast and production drift stays low.

## Conventions

- **Apps:** `k8s/apps/<app>/base` + `k8s/apps/<app>/overlays/<env>` (Kustomize only).
- **Platform:** `k8s/platform/<component>` backed by Helm values in `k8s/helm/values/<env>`.
- **Entrypoints:** `k8s/clusters/<env>/kustomization.yaml` is the only apply target per environment.
- **Labels:** use `app.kubernetes.io/name`, `app.kubernetes.io/instance`, `app.kubernetes.io/part-of`, `environment`, and `owner` consistently.
- **Naming:** resource names are stable and explicit; avoid generated suffixes unless required by a chart.

## Workload baseline checklist (must-have per app)

- [ ] **Resources:** requests and limits for CPU and memory.
- [ ] **Probes:** readiness + liveness; startup when cold start is non-trivial.
- [ ] **Security context:**
  - [ ] Pod: `runAsNonRoot`, `seccompProfile: RuntimeDefault`.
  - [ ] Container: `allowPrivilegeEscalation: false`, `capabilities.drop: ["ALL"]`, `readOnlyRootFilesystem: true` when possible.
- [ ] **ServiceAccount:** one per workload with `automountServiceAccountToken: false` unless needed.
- [ ] **PodDisruptionBudget:** set `minAvailable` or `maxUnavailable` aligned with replicas.
- [ ] **HPA:** CPU-based at minimum; memory if relevant.
- [ ] **Topology spread or anti-affinity:** keep replicas from collocating on one node/zone.
- [ ] **NetworkPolicy:** default deny + explicit allowlist for ingress/egress (DNS, data stores, dependencies).

## Platform baseline checklist (cluster-wide)

- [ ] **Ingress controller:** ingress-nginx (or equivalent) with explicit class.
- [ ] **TLS:** cert-manager with a `ClusterIssuer` (Route53 DNS01 for AWS).
- [ ] **DNS:** external-dns for Route53 zone management.
- [ ] **Metrics:** metrics-server for HPA.
- [ ] **Monitoring:** kube-prometheus-stack baseline (Prometheus, Alertmanager, Grafana).
- [ ] **Logging:** Loki + promtail or fluent-bit (pick one).
- [ ] **Tracing:** OpenTelemetry Collector + Tempo (or compatible backend).
- [ ] **Namespaces:** per team/app namespace with ResourceQuota + LimitRange.
- [ ] **Policy engine:** Kyverno or Gatekeeper with baseline admission policies.
- [ ] **Secrets:** External Secrets or Sealed Secrets (no raw Secret manifests in git).

## Security and compliance defaults

- Namespace labels enforce Pod Security Admission `restricted` by default.
- Images are pinned to immutable tags in prod (prefer digests).
- No privileged pods, host networking, or hostPath volumes without an explicit exception.

## Config and secrets

- ConfigMaps are for non-sensitive configuration only.
- Secrets are sourced from AWS Secrets Manager or SSM via External Secrets (or Sealed Secrets for sealed blobs).
- Secret templates may exist in git but are not referenced by kustomize or applied directly.

## Environment differences (allowed)

- `dev`: lower replicas, smaller resource limits, shorter retention, relaxed alert thresholds.
- `prod`: higher replicas, stricter PDB/HPA settings, pinned images, stricter policy enforcement.
