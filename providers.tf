terraform {
  required_version = "= 1.7.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 5.100.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "= 3.6.3"
    }
  }

  # Backend configured externally via -backend-config
  # key = "${var.cluster_name}/valkey/terraform.tfstate"
}

provider "aws" {
  region = var.aws_region

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  skip_region_validation      = true

  default_tags {
    tags = local.full_tags
  }
}
