locals {
  env_config = read_terragrunt_config(
    find_in_parent_folders("env.hcl")
  )

  env           = local.env_config.locals.env
  aws_region    = local.env_config.locals.aws_region
  is_local_env  = local.env == "local"
}

remote_state {
  backend = local.is_local_env ? "local" : "s3"

  config = local.is_local_env ? {
    path = "${path_relative_to_include()}/terraform.tfstate"
  } : {
    bucket         = "tf-state-${local.env}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.aws_region
    encrypt        = true
    dynamodb_table = "tf-lock-${local.env}"
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"

  contents = <<EOF
provider "aws" {
  region = "${local.aws_region}"

%{ if local.is_local_env }
  access_key = "test"
  secret_key = "test"

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    ec2 = "http://localhost:4566"
  }
%{ endif }

}
EOF
}
