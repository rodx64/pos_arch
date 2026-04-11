include "root" {
  path = "${get_repo_root()}/fase_4/tech_challenge/toggle-master-microservices/terraform/root.hcl"
}

remote_state {
  backend = "s3"
  config = {
    bucket         = "toggle-iac-state"
    key            = "observability/dev/terraform.tfstate"
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
  source = "${get_repo_root()}/fase_4/tech_challenge/toggle-master-microservices/terraform/modules/observability"
}

dependency "infra" {
  config_path  = "${get_repo_root()}/fase_4/tech_challenge/toggle-master-microservices/terraform/environments/dev/"
  skip_outputs = false

  # mock - "somente para os comandos validate e plan. Se o output real não estiver disponível, use os valores fictícios abaixo em vez de falhar."
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    eks_cluster_endpoint = "https://mock"
    eks_cluster_ca       = "bW9jaw=="
    eks_cluster_token    = "mock"
  }
}

inputs = {
  namespace            = "monitoring"

  eks_cluster_endpoint = dependency.infra.outputs.eks_cluster_endpoint
  eks_cluster_ca       = dependency.infra.outputs.eks_cluster_ca
  eks_cluster_token    = dependency.infra.outputs.eks_cluster_token
  eks_tunnel_host      = "https://127.0.0.1:6443"

  # dev: retenção curta e scrape menos frequente
  prometheus_retention = "2d"
  scrape_interval      = "30s"

  datadog_site         = "datadoghq.com"
  datadog_api_key      = get_env("DATADOG_API_KEY", "")
}
