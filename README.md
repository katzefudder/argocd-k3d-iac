# Argo CD on local k3d, fully reproducible (IaC + GitOps)

This repo gives you a **fresh, repeatable** way to spin up:
- a **local k3d** Kubernetes cluster (k3s-in-docker)
- **Argo CD installed via Helm**
- a **GitOps “app-of-apps” bootstrap** that deploys a sample app from this repo

Everything is driven by **Terraform** (cluster + Argo CD install + bootstrap objects) and then **Argo CD** takes over app delivery.

---

## Prereqs

Install these locally:
- Docker
- `k3d`
- `kubectl`
- `helm`
- `terraform` (1.5+ recommended)

Verify:
```bash
docker version
k3d version
kubectl version --client
helm version
terraform version
```

---

## Quick start

### 1) Fork this repo to GitHub
Argo CD needs a Git URL it can pull from. Fork, then note your repo URL (e.g. `https://github.com/<you>/argocd-k3d-iac.git`).

### 2) Create the cluster + install Argo CD + bootstrap apps
```bash
make up GIT_REPO_URL=https://github.com/<you>/argocd-k3d-iac.git
```

### 3) Open Argo CD UI
In a second terminal:
```bash
make argocd-port-forward
```

Then open:
- http://localhost:8080

Login:
```bash
make argocd-password
```
User is `admin`.

### 4) Check the demo app
The bootstrap installs a small NGINX “hello” app into the `demo` namespace.

Port-forward it:
```bash
kubectl -n demo port-forward svc/hello 9090:80
```
Open:
- http://localhost:9090

---

## Tear down

```bash
make destroy
```

---

## Repo layout

- `infra/terraform/`  
  Terraform: k3d cluster, kubeconfig, Argo CD Helm release, and a bootstrap `Application` manifest.
- `apps/root/`  
  The Argo CD “app-of-apps” entry point.
- `apps/hello/`  
  A simple Kustomize app (Deployment + Service).

---

## Notes / troubleshooting

- If Terraform fails because the cluster already exists:
  ```bash
  k3d cluster delete argocd-demo
  ```
- If `kubectl` context is wrong:
  ```bash
  kubectl config use-context k3d-argocd-demo
  ```
- Argo CD initial admin password comes from `argocd-initial-admin-secret`:
  ```bash
  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
  ```

---

## Why this is “start fresh”
- `make destroy` removes both the **k3d cluster** and **Terraform state**
- `make up` recreates everything deterministically

Have fun iterating: change the manifests under `apps/` and Argo CD will reconcile.
