include "root" {
  path = "${get_repo_root()}/fase_5/tech_challenge/solidary-tech/terraform/root.hcl"
}

remote_state {
  backend = "s3"
  config = {
    bucket         = "solidary-iac-state"
    key            = "db-migrations/dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
}

terraform {
  source = "${get_repo_root()}/fase_5/tech_challenge/solidary-tech/terraform/modules/db-migrations"
}

dependency "infra" {
  config_path = "${get_repo_root()}/fase_5/tech_challenge/solidary-tech/terraform/environments/dev/"
}

dependency "secrets" {
  config_path = "${get_repo_root()}/fase_5/tech_challenge/solidary-tech/k8s-secrets/dev/"
}

inputs = {
  namespace = "solidary-tech"

  donation_db_url = dependency.secrets.outputs.donation_db_url
  ngo_db_url      = dependency.secrets.outputs.ngo_db_url

  donation_migration_image = "356969227282.dkr.ecr.us-east-1.amazonaws.com/solidary-tech:donation-service-migration-66f81512f8d96494d183e447337fa30975ea5767"
  ngo_migration_image      = "356969227282.dkr.ecr.us-east-1.amazonaws.com/solidary-tech:ngo-service-migration-66f81512f8d96494d183e447337fa30975ea5767"

  eks_cluster_endpoint = dependency.infra.outputs.eks_cluster_endpoint
  eks_cluster_ca       = dependency.infra.outputs.eks_cluster_ca
  eks_cluster_token = run_cmd("--terragrunt-quiet", "aws", "eks", "get-token", "--cluster-name", "solidary-tech-eks", "--query", "status.token", "--output", "text")
  
  eks_tunnel_host      = "https://127.0.0.1:6443"
}

