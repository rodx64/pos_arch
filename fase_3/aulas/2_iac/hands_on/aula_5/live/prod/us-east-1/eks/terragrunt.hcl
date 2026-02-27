include "env" {
  path = find_in_parent_folders("terragrunt.hcl")
}

terraform {
  source = "../../../../modules/eks"
}

dependency "vpc" {
  config_path = "../vpc"
}

inputs = {
  cluster_name   = "eks-prod"
  vpc_id         = dependency.vpc.outputs.vpc_id
  subnet_ids     = dependency.vpc.outputs.public_subnet_ids
  k8s_version    = "1.29"
  instance_types = ["t3.medium"]
  desired_size   = 3
  min_size       = 2
  max_size       = 5
  capacity_type  = "ON_DEMAND"
}
