SHELL := /bin/bash

# Example:
#   make up GIT_REPO_URL=https://github.com/<you>/argocd-k3d-iac.git
GIT_REPO_URL ?= https://github.com/katzefudder/argocd-k3d-iac.git

.PHONY: up destroy argocd-password argocd-port-forward kubecontext deploy-apps

up:
	cd infra/terraform && terraform init
	cd infra/terraform && terraform apply -auto-approve -var="git_repo_url=$(GIT_REPO_URL)"
	@echo "Terraform infrastructure is ready. Run 'make deploy-apps' to deploy ArgoCD applications."

deploy-apps:
	@bash scripts/deploy-apps.sh $(GIT_REPO_URL)

destroy:
	cd infra/terraform && terraform destroy -auto-approve || true
	k3d cluster delete argocd-demo || true
	rm -rf infra/terraform/.terraform infra/terraform/.terraform.lock.hcl infra/terraform/terraform.tfstate infra/terraform/terraform.tfstate.backup || true

kubecontext:
	kubectl config use-context k3d-argocd-demo

argocd-password:
	kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

argocd-port-forward:
	kubectl -n argocd port-forward svc/argocd-server 8080:80
