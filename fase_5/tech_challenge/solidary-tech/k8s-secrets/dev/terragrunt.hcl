include "root" {
  path = "${get_repo_root()}/fase_5/tech_challenge/solidary-tech/terraform/root.hcl"
}

remote_state {
  backend = "s3"
  config = {
    bucket         = "solidary-iac-state"
    key            = "k8s-secrets/dev/terraform.tfstate"
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
  source = "${get_repo_root()}/fase_5/tech_challenge/solidary-tech/terraform/modules/k8s-secrets"
}

dependency "infra" {
  config_path  = "${get_repo_root()}/fase_5/tech_challenge/solidary-tech/terraform/environments/dev/"
  skip_outputs = false

  # mock - "somente para os comandos validate e plan. Se o output real não estiver disponível, use os valores fictícios abaixo em vez de falhar."
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    rds_endpoints        = { "donation-db" = "mock:5432", "ngo-db" = "mock:5432" }
    rds_secret_arns      = { "donation-db" = "mock", "ngo-db" = "mock" }
    dynamodb_table_names = { "volunteer-table" = "mock_table" }
    sqs_queue_urls       = { "donation-queue" = "https://mock" }
    eks_cluster_endpoint = "https://mock"
    eks_cluster_ca       = "bW9jaw=="
    eks_cluster_token    = "mock"
  }
}

inputs = {
  namespace = "solidary-tech"

  donation_db_endpoint   = dependency.infra.outputs.rds_endpoints["donation-db"]
  donation_db_secret_arn = dependency.infra.outputs.rds_secret_arns["donation-db"]
  ngo_db_endpoint        = dependency.infra.outputs.rds_endpoints["ngo-db"]
  ngo_db_secret_arn      = dependency.infra.outputs.rds_secret_arns["ngo-db"]
  
  dynamodb_table_name     = dependency.infra.outputs.dynamodb_table_names["volunteer-table"]
  sqs_queue_url           = dependency.infra.outputs.sqs_queue_urls["donation-queue"]
  
  eks_cluster_endpoint    = dependency.infra.outputs.eks_cluster_endpoint
  eks_cluster_ca          = dependency.infra.outputs.eks_cluster_ca
  eks_cluster_token       = dependency.infra.outputs.eks_cluster_token
  eks_tunnel_host         = "https://127.0.0.1:6443"
}
