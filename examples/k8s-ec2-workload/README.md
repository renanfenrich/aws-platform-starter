# Kubernetes (EC2) Workload (Example)

This is an optional, non-production example. It is illustrative only.

## What this demonstrates

- A minimal workload deployed to the self-managed Kubernetes (EC2) platform
- ALB -> NodePort ingress routing using the platform-provided NodePort
- Image wiring from the environment ECR repository output
- Basic configuration via a ConfigMap

## What this does NOT do

- Provision Kubernetes resources via Terraform
- Provide CI/CD or application source code
- Sync Secrets Manager into Kubernetes (manual step only)

## How it relates to the platform

- Assumes `platform = "k8s_self_managed"` and reuses the ALB/NodePort wiring created by the environment.
- Uses the manifests in `k8s/` as the workload source; this example just shows how to apply them.
- The example is removable without impacting the platform stack.

## Usage (optional)

1) Deploy the platform with `platform = "k8s_self_managed"`.
2) Connect to the control plane using the environment output:

```bash
terraform output -raw cluster_access_instructions
```

3) Apply the manifests (dev shown):

```bash
kubectl apply -k k8s/overlays/dev
```

4) Point the Deployment at the environment ECR image:

```bash
kubectl set image deployment/demo-app app=$(terraform output -raw resolved_container_image) -n demo
```

Notes:
- The ALB target group health check path is `health_check_path` in the environment. Keep it aligned with `k8s/base/ingress.yaml` and the probes in `k8s/base/deployment.yaml`.
- The ingress controller NodePort should match `terraform output -raw k8s_ingress_nodeport`.
- If you need secrets, copy `k8s/base/secret-template.yaml`, replace values, and patch the Deployment to reference it.
