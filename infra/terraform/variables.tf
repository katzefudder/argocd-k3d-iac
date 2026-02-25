variable "cluster_name" {
  type        = string
  default     = "argocd-demo"
  description = "k3d cluster name"
}

variable "servers" {
  type        = number
  default     = 1
  description = "k3d server nodes"
}

variable "agents" {
  type        = number
  default     = 1
  description = "k3d agent nodes"
}

variable "git_repo_url" {
  type        = string
  description = "Git repo URL (HTTPS) that Argo CD can pull from. Fork this repo and pass your URL."
}

variable "argocd_chart_version" {
  type        = string
  default     = "9.4.3"
  description = "Argo CD Helm chart version (argo/argo-cd)"
}
