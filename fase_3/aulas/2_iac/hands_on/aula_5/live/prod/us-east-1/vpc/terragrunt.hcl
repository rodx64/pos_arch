include "env" {
  path = find_in_parent_folders("terragrunt.hcl")
}

terraform {
  source = "../../../../modules/vpc"
}

inputs = {
  name       = "prod-vpc"
  cidr_block = "10.20.0.0/16"
  azs        = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnet_cidrs = ["10.20.1.0/24", "10.20.2.0/24", "10.20.3.0/24"]
}
