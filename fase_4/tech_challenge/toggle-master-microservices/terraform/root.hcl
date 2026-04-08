locals {
  modules_path = "${path_relative_from_include()}/modules"
}

remote_state {
  backend = "s3"
  config = {
    bucket         = "toggle-iac-state"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
