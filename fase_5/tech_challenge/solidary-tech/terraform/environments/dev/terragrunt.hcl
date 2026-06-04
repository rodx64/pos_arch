include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "${get_parent_terragrunt_dir()}//modules/root"

  after_hook "patch_eks" {
    commands = ["init"]
    execute  = ["bash", "${get_parent_terragrunt_dir()}/patch_eks.sh"]
    run_on_error = false
  }
}

inputs = {
  ### GENERAL
  env             = "dev"
  project_name    = "solidary-tech"
  
  ### VPC
  vpc_cidr        = "10.0.0.0/16"
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.3.0/24", "10.0.4.0/24"]
  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  
  ### ECR
  ecr_repositories = ["donation-service", "ngo-service", "volunteer-service"]
  force_delete     = true

  ### RDS
  databases = {
    donation-db = {
      db_name        = "donation_db"
      db_user        = "postgres"
      app_owner_name = "donation-service"
    }
    ngo-db = {
      db_name        = "ngo_db"
      db_user        = "postgres"
      app_owner_name = "ngo-service"
    }
  }

  ### SQS
  sqs_queues = {
    donations = {
      queue_name                 = "donation-events-queue"
      visibility_timeout_seconds = 30
      message_retention_seconds  = 86400
      create_dlq                 = true
      max_receive_count          = 3
    }
  }

  ### DynamoDB
  dynamodb_tables = {
    volunteers = {
      table_name = "volunteers"
      hash_key   = "volunteer_id"
    }
  }

  ### EC2 (BASTION)
  ami_id        = "ami-0b6c6ebed2801a5cb" # Ubuntu Server 24.04 (x64)
  instance_type = "t3.small"
  key_name      = "iac-key"
  project_name  = "solidary-tech"

  ### EKS
  enable_eks         = true
  kubernetes_version = "1.34"
  instance_types     = ["t3.medium"]
}
