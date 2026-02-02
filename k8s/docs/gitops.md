# GitOps with Argo CD

This repo bootstraps Argo CD from the environment entrypoints under `k8s/clusters/<env>`. The initial apply installs Argo CD and creates an Application that points back at the same entrypoint, so Argo takes over after the first apply.

## Bootstrap

1) Apply the environment entrypoint:

```bash
kubectl apply -k k8s/clusters/dev
```

2) Wait for the `argocd` namespace to become ready and for Argo CD pods to start.

## Access the Argo CD UI

Use a local port-forward (no ingress in this repo):

```bash
kubectl -n argocd port-forward svc/argocd-server 8080:443
```

Then open `https://localhost:8080` in your browser.

## Initial admin password

Argo CD stores the initial admin password in a Secret. Retrieve it locally and avoid logging it:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
```

Username is `admin` by default. Rotate the password after first login.

## Environment behavior

- `dev` (`platform-dev` Application): automated sync with prune + self-heal.
- `prod` (`platform-prod` Application): manual sync only, prune disabled by default.

## Adding a new workload or platform component

1) Add the Kustomize base/overlay under `k8s/apps/<app>` or `k8s/platform/<component>`.
2) Reference the new overlay in `k8s/clusters/<env>/kustomization.yaml`.
3) Commit and push; Argo CD reconciles the change from the repo path.

## Notes and trade-offs

- Argo CD is pinned to v3.2.2 via `k8s/platform/argocd/base/install.yaml`.
- Argo CD workloads carry policy exceptions for missing probes/resources to keep the vendored manifest close to upstream defaults. Tighten with explicit requests/limits and probes if you harden the platform.
- Repo access is currently `*` in the AppProject for bootstrap simplicity. Tighten it to the exact repo URL once Argo is stable.
- Argo CD is installed by plain manifests pinned in git. Version changes require updating the vendored manifest.
