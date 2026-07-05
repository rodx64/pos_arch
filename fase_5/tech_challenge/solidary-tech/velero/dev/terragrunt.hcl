include "root" {
  path = "${get_repo_root()}/fase_5/tech_challenge/solidary-tech/terraform/root.hcl"
}

remote_state {
  backend = "s3"
  config = {
    bucket         = "solidary-iac-state"
    key            = "velero/dev/terraform.tfstate"
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
  source = "${get_repo_root()}/fase_5/tech_challenge/solidary-tech/terraform/modules/velero"
}

inputs = {
  environment = "dev"
}
