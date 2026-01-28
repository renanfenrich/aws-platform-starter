# Kubernetes Policy Rules

This folder contains Conftest policies for repo-managed Kubernetes manifests. The policies are intentionally strict; exceptions must be explicit and justified in the PR description.

## How policies are evaluated

- Kustomize overlays are the default input for policy checks.
- Policies are evaluated with Conftest via `make k8s-policy` and `make k8s-sec`.

## Exception mechanism

Policies can be bypassed per-resource or per-pod-template using annotations.
Use these only with a written justification in the PR.

Annotations are boolean strings ("true").

| Annotation | What it allows |
| --- | --- |
| `policy.aws-platform-starter/allow-missing-labels` | Skip required labels check |
| `policy.aws-platform-starter/allow-missing-resources` | Skip CPU/memory requests+limits check |
| `policy.aws-platform-starter/allow-missing-probes` | Skip liveness/readiness probes |
| `policy.aws-platform-starter/allow-loadbalancer` | Allow Service type LoadBalancer |
| `policy.aws-platform-starter/allow-privileged` | Allow privileged containers |
| `policy.aws-platform-starter/allow-host-namespace` | Allow hostNetwork/hostPID/hostIPC |
| `policy.aws-platform-starter/allow-run-as-root` | Allow runAsNonRoot exception |
| `policy.aws-platform-starter/allow-capabilities` | Allow dropping ALL capabilities exception |
| `policy.aws-platform-starter/allow-plaintext-secret` | Allow plaintext Secret data |
| `policy.aws-platform-starter/secret-encrypted` | Mark an encrypted Secret as acceptable |

## Policy summary

### Policy rules (`k8s-policy`)
- Require standard labels on all workload/support resources.
- Require CPU/memory requests and limits for containers and initContainers.
- Require liveness and readiness probes for long-running workloads.
- Disallow Service type LoadBalancer without an explicit exception.

### Security rules (`k8s-sec`)
- Disallow privileged containers by default.
- Disallow hostNetwork/hostPID/hostIPC by default.
- Require `runAsNonRoot` on pods or containers.
- Require dropping ALL Linux capabilities.
- Disallow plaintext Secrets unless marked as encrypted or explicitly allowed.
