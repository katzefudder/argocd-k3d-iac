#!/bin/bash
set -euo pipefail

# Script to deploy the App-of-Apps after Terraform infrastructure is ready
# Usage: ./deploy-apps.sh <git-repo-url>

if [ $# -ne 1 ]; then
  echo "Usage: $0 <git-repo-url>"
  echo "Example: $0 https://github.com/katzefudder/argocd-k3d-iac"
  exit 1
fi

GIT_REPO_URL="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Deploying App-of-Apps..."
echo "Git Repository: $GIT_REPO_URL"

# Deploy the app-of-apps which manages all other applications
echo "Deploying app-of-apps..."
kubectl apply -f "${SCRIPT_DIR}/app-of-apps.yaml"

echo "App-of-Apps deployed successfully!"
echo ""
echo "Monitor progress with:"
echo "  kubectl get app -n argocd"
echo "  argocd app list"
echo ""
echo "To access ArgoCD:"
echo "  Port-forward: make argocd-port-forward"
echo "               Then open http://localhost:8080"
echo ""
echo "  Or via Ingress:"
echo "    Add to /etc/hosts: 127.0.0.1 argocd.localhost"
echo "    Then open http://argocd.localhost"
echo ""
echo "Login credentials:"
echo "  Username: admin"
echo "  Password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d || echo 'Run: make argocd-password')"


