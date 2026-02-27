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
  cluster_name   = "eks-dev"
  vpc_id         = dependency.vpc.outputs.vpc_id
  subnet_ids     = dependency.vpc.outputs.public_subnet_ids # simplificação didática
  k8s_version    = "1.29"
  instance_types = ["t3.small"]
  desired_size   = 2
  min_size       = 1
  max_size       = 3
}
