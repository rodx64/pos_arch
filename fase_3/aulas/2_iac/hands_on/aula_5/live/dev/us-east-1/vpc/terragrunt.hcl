include "env" {
  path = find_in_parent_folders("terragrunt.hcl")
}

terraform {
  source = "../../../../modules/vpc"
}

inputs = {
  name       = "dev-vpc"
  cidr_block = "10.10.0.0/16"
  azs        = ["us-east-1a", "us-east-1b"]
  # opcional: defina manualmente CIDRs das públicas para previsibilidade
  public_subnet_cidrs = ["10.10.1.0/24", "10.10.2.0/24"]
}
