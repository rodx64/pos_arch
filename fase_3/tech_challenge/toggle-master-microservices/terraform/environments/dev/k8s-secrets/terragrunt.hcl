include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "${get_parent_terragrunt_dir()}//modules/k8s-secrets"
}

dependency "infra" {
  config_path = "../"

  mock_outputs = {
    rds_endpoints   = { auth-db = "mock:5432", flag-db = "mock:5432", analytics-db = "mock:5432" }
    rds_secret_arns = { auth-db = "arn:aws:secretsmanager:us-east-1:123456789:secret:mock", flag-db = "arn:aws:secretsmanager:us-east-1:123456789:secret:mock", analytics-db = "arn:aws:secretsmanager:us-east-1:123456789:secret:mock" }
    dynamodb_table_names = { analytics-events = "mock_table" }
    sqs_queue_urls       = { analytics = "https://mock" }
    eks_cluster_name     = "mock-cluster"
    eks_cluster_endpoint = "https://mock"
    eks_cluster_ca       = "mock"
    eks_cluster_token    = "mock"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
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

  auth_master_key    = get_env("TF_VAR_AUTH_MASTER_KEY", "")
  evaluation_api_key = get_env("TF_VAR_EVALUATION_API_KEY", "")

  namespace = "toggle-master"
}
