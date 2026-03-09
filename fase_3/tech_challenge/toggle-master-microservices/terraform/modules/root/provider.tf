terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0, < 6.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
  }
}

provider "aws" {}

provider "kubernetes" {
  host = try(data.aws_eks_cluster.this[0].endpoint, "")
  cluster_ca_certificate = try(
    base64decode(data.aws_eks_cluster.this[0].certificate_authority[0].data),
    ""
  )
  token = try(data.aws_eks_cluster_auth.this[0].token, "")
}
