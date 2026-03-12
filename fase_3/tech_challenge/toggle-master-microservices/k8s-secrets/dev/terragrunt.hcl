include "root" {
  path = "${get_repo_root()}/fase_3/tech_challenge/toggle-master-microservices/terraform/root.hcl"
}

remote_state {
  backend = "s3"
  config = {
    bucket         = "toggle-iac-state"
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
  source = "${get_repo_root()}/fase_3/tech_challenge/toggle-master-microservices/terraform/modules/k8s-secrets"
}

dependency "infra" {
  config_path  = "${get_repo_root()}/fase_3/tech_challenge/toggle-master-microservices/terraform/environments/dev/"
  skip_outputs = false

  mock_outputs_allowed_terraform_commands = ["validate"]
  mock_outputs = {
    rds_endpoints        = { "auth-db" = "mock:5432", "flag-db" = "mock:5432", "analytics-db" = "mock:5432" }
    rds_secret_arns      = { "auth-db" = "mock", "flag-db" = "mock", "analytics-db" = "mock" }
    dynamodb_table_names = { "analytics-events" = "mock_table" }
    sqs_queue_urls       = { "analytics" = "https://mock" }
    eks_cluster_endpoint = "https://mock"
    eks_cluster_ca       = "bW9jaw=="
    eks_cluster_token    = "mock"
  }
}

inputs = {
  auth_db_endpoint      = dependency.infra.outputs.rds_endpoints["auth-db"]
  flag_db_endpoint      = dependency.infra.outputs.rds_endpoints["flag-db"]
  analytics_db_endpoint = dependency.infra.outputs.rds_endpoints["analytics-db"]

  auth_db_secret_arn      = dependency.infra.outputs.rds_secret_arns["auth-db"]
  flag_db_secret_arn      = dependency.infra.outputs.rds_secret_arns["flag-db"]
  analytics_db_secret_arn = dependency.infra.outputs.rds_secret_arns["analytics-db"]

  dynamodb_table_name = dependency.infra.outputs.dynamodb_table_names["analytics-events"]
  sqs_queue_url       = dependency.infra.outputs.sqs_queue_urls["analytics"]

  eks_cluster_endpoint = dependency.infra.outputs.eks_cluster_endpoint
  eks_cluster_ca       = dependency.infra.outputs.eks_cluster_ca
  eks_cluster_token    = dependency.infra.outputs.eks_cluster_token
  eks_tunnel_host      = "https://127.0.0.1:6443"

  auth_master_key    = get_env("TF_VAR_AUTH_MASTER_KEY", "")
  evaluation_api_key = get_env("TF_VAR_EVALUATION_API_KEY", "")

  namespace = "toggle-master"
}
