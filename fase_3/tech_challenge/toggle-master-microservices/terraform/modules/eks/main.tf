module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.21.0"

  cluster_name    = "${var.project_name}-eks"
  cluster_version = var.kubernetes_version

  subnet_ids = var.private_subnet_ids
  vpc_id     = var.vpc_id

  # Usa roles pré-criadas — não tenta criar novas
  create_iam_role = false
  iam_role_arn    = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"

  enable_irsa = false
  create_kms_key            = false
  cluster_encryption_config = {}

  eks_managed_node_groups = {
    "${var.project_name}-ng" = {
      min_size       = 1
      max_size       = 3
      desired_size   = 2
      instance_types = var.instance_types

      # Mesma regra para os nodes
      create_iam_role = false
      iam_role_arn    = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"
    }
  }

  tags = {
    Project = var.project_name
  }
}

data "aws_caller_identity" "current" {}
