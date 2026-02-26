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
        k3d cluster create -p "80:80@loadbalancer" -p "443:443@loadbalancer" ${var.cluster_name} --k3s-arg "--disable=traefik@server:0" --servers ${var.servers} --agents ${var.agents}
      fi

      echo "Writing kubeconfig to ${local.kubeconfig_path}..."
      k3d kubeconfig get ${var.cluster_name} > ${local.kubeconfig_path}

      echo "Switching kubectl context..."
      kubectl config use-context k3d-${var.cluster_name} >/dev/null

      echo "Installing nginx Ingress Controller via Helm..."
      helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace

      sleep 10 # Wait for the Ingress Controller to be ready (in a real setup, you'd want to check the deployment status instead of sleeping)
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
        insecure = true
        ingress = {
          enabled = false
          /*
          ingressClassName = "nginx"
          hostname = "argocd.localhost"
          path = "/"
          pathType = "Prefix"
          annotations = {
            "nginx.ingress.kubernetes.io/force-ssl-redirect" = "false"
            "nginx.ingress.kubernetes.io/backend-protocol" = "HTTP"
            "nginx.ingress.kubernetes.io/ssl-redirect" = "false"
          }
          */
        }
      }
      configs = {
        server = {
          insecure = true
          url = "http://argocd.localhost"
        }
      }
    })
  ]
}