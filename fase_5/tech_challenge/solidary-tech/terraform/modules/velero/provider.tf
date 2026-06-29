terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0, < 6.0.0"
    }
  }
}

provider "aws" {
  default_tags {
    tags = {
      Project     = "SolidaryTech"
      Environment = title(var.environment)
      CostCenter  = "NGO-Core"
      ManagedBy   = "Terraform"
    }
  }
}

provider "aws" {
  alias  = "dr"
  region = var.dr_region
}
