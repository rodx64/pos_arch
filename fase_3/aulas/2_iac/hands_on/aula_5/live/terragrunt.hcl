# live/terragrunt.hcl
locals {
  aws_region   = "us-east-1"
  state_bucket = "REPLACE_ME_BUCKET"
  lock_table   = "REPLACE_ME_LOCK_TABLE"
}

remote_state {
  backend = "s3"
  config = {
    bucket         = local.state_bucket
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.aws_region
    dynamodb_table = local.lock_table
    encrypt        = true
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<EOF
provider "aws" {
  region = "${local.aws_region}"
}
EOF
}
