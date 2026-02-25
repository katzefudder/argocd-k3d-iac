#!/usr/bin/env bash
set -euo pipefail

echo "Contexts:"
kubectl config get-contexts | sed -n '1,6p'

echo
echo "Argo CD pods:"
kubectl -n argocd get pods

echo
echo "Applications:"
kubectl -n argocd get applications.argoproj.io
