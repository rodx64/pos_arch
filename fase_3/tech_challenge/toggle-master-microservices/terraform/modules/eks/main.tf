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

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = false
  cluster_additional_security_group_ids = [var.bastion_sg_id]

  eks_managed_node_groups = {
    "${var.project_name}-ng" = {
      min_size       = 1
      max_size       = 4
      desired_size   = 3
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

resource "aws_security_group_rule" "bastion_to_eks" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = var.bastion_sg_id
  security_group_id        = module.eks.cluster_security_group_id
  description              = "Allow bastion to reach EKS API"
}
