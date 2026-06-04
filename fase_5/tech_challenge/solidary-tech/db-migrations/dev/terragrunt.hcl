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

  donation_migration_image = "356969227282.dkr.ecr.us-east-1.amazonaws.com/solidary-tech:donation-service-migration-9ef814482417825b1030bbfec7a450091f32ae5a"
  ngo_migration_image      = "356969227282.dkr.ecr.us-east-1.amazonaws.com/solidary-tech:ngo-service-migration-8cee1fe85606f373b1e52c2dc22ac40b67ee8ddf"

  eks_cluster_endpoint = dependency.infra.outputs.eks_cluster_endpoint
  eks_cluster_ca       = dependency.infra.outputs.eks_cluster_ca
  eks_cluster_token = run_cmd("--terragrunt-quiet", "aws", "eks", "get-token", "--cluster-name", "solidary-tech-eks", "--query", "status.token", "--output", "text")
  
  eks_tunnel_host      = "https://127.0.0.1:6443"
}

