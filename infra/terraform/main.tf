locals {
  kubeconfig_path = "${path.module}/.kubeconfig"
}

# --- 1) Create k3d cluster (k3s in docker) ---
resource "null_resource" "k3d_cluster" {
  triggers = {
    cluster_name = var.cluster_name
    servers      = tostring(var.servers)
    agents       = tostring(var.agents)
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail

      if k3d cluster list | grep -q "^${var.cluster_name}\b"; then
        echo "k3d cluster '${var.cluster_name}' already exists"
      else
        echo "Creating k3d cluster '${var.cluster_name}'..."
        k3d cluster create ${var.cluster_name}           --servers ${var.servers}           --agents ${var.agents}           --k3s-arg "--disable=traefik@server:0"
      fi

      echo "Writing kubeconfig to ${local.kubeconfig_path}..."
      k3d kubeconfig get ${var.cluster_name} > ${local.kubeconfig_path}

      echo "Switching kubectl context..."
      kubectl config use-context k3d-${var.cluster_name} >/dev/null
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
}

# --- 2) Providers configured from the kubeconfig file produced above ---
provider "kubernetes" {
  config_path = local.kubeconfig_path
}

provider "helm" {
  kubernetes = {
    config_path = local.kubeconfig_path
  }
}

# --- 3) Install Argo CD via Helm ---
resource "helm_release" "argocd" {
  depends_on = [null_resource.k3d_cluster]

  name       = "argocd"
  namespace  = "argocd"
  create_namespace = true

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_chart_version

  # Keep it simple for local dev:
  # - Use ClusterIP service and access via kubectl port-forward
  # - Reduce replicas (optional) for small laptops
  values = [
    yamlencode({
      server = {
        replicas = 1
        service = { type = "ClusterIP" }
      }
      repoServer = { replicas = 1 }
      applicationSet = { replicas = 1 }
      controller = { replicas = 1 }
    })
  ]
}

# --- 4) Bootstrap GitOps (App-of-Apps) ---
# This creates an Argo CD Application that points back to this repo's apps/root folder.
resource "kubernetes_manifest" "root_app" {
  depends_on = [helm_release.argocd]

  manifest = yamldecode(templatefile("${path.module}/templates/root-app.yaml.tftpl", {
    git_repo_url = var.git_repo_url
  }))
}
