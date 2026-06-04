data "aws_eks_cluster" "this" {
  count      = var.enable_eks ? 1 : 0
  name       = module.eks[0].cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "this" {
  count      = var.enable_eks ? 1 : 0
  name       = module.eks[0].cluster_name
  depends_on = [module.eks]
}
