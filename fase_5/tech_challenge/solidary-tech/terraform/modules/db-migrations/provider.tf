terraform {
  required_version = ">= 1.5"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
  }
}

provider "kubernetes" {
  host                   = var.eks_tunnel_host != "" ? var.eks_tunnel_host : var.eks_cluster_endpoint
  cluster_ca_certificate = var.eks_tunnel_host != "" ? "" : base64decode(var.eks_cluster_ca)
  insecure               = var.eks_tunnel_host != ""
  token                  = var.eks_cluster_token
}
