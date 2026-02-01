# Kubernetes demo manifests

These manifests are intentionally small but hardened. They target the self-managed kubeadm cluster and assume an ALB that forwards to a NodePort ingress controller service. The control plane bootstrap installs flannel and ingress-nginx, and patches the ingress service to the configured NodePort.

## Status

This directory is transitioning to a production-grade layout with minimal churn. The plan and standards live in:

- `k8s/docs/plan.md`
- `k8s/docs/standards.md`

Kustomize stays the default for app overlays; Helm is reserved for third-party platform charts.

## Current layout

- `clusters/dev`: dev entrypoint (references the overlay)
- `clusters/prod`: prod entrypoint (references the overlay)
- `base/`: shared resources
- `overlays/dev`: dev patch set (implementation detail)
- `overlays/prod`: prod patch set (implementation detail)
- `kind-config.yaml`: local kind config

## Quickstart (recommended entrypoints)

Apply:

```bash
kubectl apply -k k8s/clusters/dev
kubectl apply -k k8s/clusters/prod
```

Preview and dry-run:

```bash
kustomize build k8s/clusters/dev | less
kubectl apply -k k8s/clusters/dev --dry-run=client
```

## Reference app template

The reference workload template lives at `k8s/apps/reference-app` and is not wired into any cluster entrypoints yet. Render it directly:

```bash
kustomize build k8s/apps/reference-app/overlays/dev
kustomize build k8s/apps/reference-app/overlays/prod
```

## Checks

Full local check suite:

```bash
scripts/kubernetes/run_checks.sh
```

Makefile targets:

```bash
make k8s-validate
make k8s-lint
make k8s-policy
make k8s-sec
```

## Ingress and ALB routing

The expected flow is:

`ALB -> NodePort ingress controller -> Ingress -> demo-service -> Pods`

If you choose the direct NodePort pattern instead, patch `k8s/base/service.yaml` to `type: NodePort` and omit the Ingress resource.

## Image updates

Use the Terraform output so the image matches the infrastructure build:

```bash
kubectl set image deployment/demo-app app=$(terraform output -raw resolved_container_image) -n demo
```

If you prefer Git-managed changes, update the image tag in the overlay patch files instead.

## Configuration and secrets

- `demo-app-config` holds non-sensitive settings via a ConfigMap.
- `k8s/base/secret-template.yaml` is a template only. Copy it, replace values, and apply it separately, or source secrets from AWS Secrets Manager/SSM at deploy time.

## Notes and trade-offs

- HPA requires metrics-server; without it the HPA status will remain `Unknown`.
- NetworkPolicy is default-deny. Add explicit egress rules for any external dependencies beyond DNS.
- The ingress allow policy assumes an `ingress-nginx` namespace; update the selector if your controller uses a different namespace.
- The DB egress policy uses the TEST-NET-3 range (`203.0.113.0/24`) as a placeholder. Replace or remove it.
- `readOnlyRootFilesystem` is set to `false` to avoid breaking unknown images. If your image is read-only safe, flip it to `true` and add an `emptyDir` mount for `/tmp` as needed.
- The Deployment expects a non-root image. If your image requires root, update the security context instead of weakening the namespace policy.
- The preStop hook uses `/bin/sh` for a short sleep; if you use a distroless image, replace it with an app-specific shutdown hook.
