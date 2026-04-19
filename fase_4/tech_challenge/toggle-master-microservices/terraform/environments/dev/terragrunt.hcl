include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "${get_parent_terragrunt_dir()}//modules/root"

  after_hook "patch_eks" {
    commands = ["init"]
    execute  = ["bash", "${get_parent_terragrunt_dir()}/patch_eks.sh"] # verificar versões mas novas para não ter de fazer o patch
    run_on_error = false
  }
}

inputs = {
  env             = "dev"
  vpc_cidr        = "10.0.0.0/16"
  public_subnets  = ["10.0.3.0/24", "10.0.4.0/24"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]

  # EC2 BASTION
  ami_id        = "ami-0b6c6ebed2801a5cb" # Ubuntu Server 24.04 (x64)
  instance_type = "t3.small"
  key_name      = "iac-key"
  project_name  = "toggle-master"

  # RDS
  databases = {
    auth-db = {
      db_name        = "auth_db"
      db_user        = "postgres"
      app_owner_name = "auth-service"
    }
    flag-db = {
      db_name        = "flag_db"
      db_user        = "postgres"
      app_owner_name = "flag-service"
    }
    analytics-db = {
      db_name        = "analytics_db"
      db_user        = "postgres"
      app_owner_name = "analytics-service"
    }
  }

  # DynamoDB
  dynamodb_tables = {
    analytics-events = {
      table_name = "analytics_events"
      hash_key   = "event_id"
    }
  }

  # SQS
  sqs_queues = {
    analytics = {
      queue_name                 = "toggle-analytics-queue"
      visibility_timeout_seconds = 30
      message_retention_seconds  = 86400
      create_dlq                 = true
      max_receive_count          = 3
    }
  }

  # REDIS
  redis_clusters = {
    evaluation = {
      cluster_id     = "redis-evaluation"
      node_type      = "cache.t3.micro"
      engine_version = "7.0"
    }
  }

  # ECR
  ecr_repositories = ["toggle-master"]
  force_delete     = true

  auth_master_key       = get_env("TF_VAR_AUTH_MASTER_KEY", "")
  evaluation_api_key    = get_env("TF_VAR_EVALUATION_API_KEY", "")

  # EKS
  enable_eks         = true
  kubernetes_version = "1.34"
  instance_types     = ["t3.medium"]
}
