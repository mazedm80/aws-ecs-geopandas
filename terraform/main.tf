terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "s3" {
  source     = "./modules/s3"
  env        = var.env
}

module "ecr" {
  source     = "./modules/ecr"
  env        = var.env
}

module "iam" {
  source     = "./modules/iam"
  env        = var.env
}

output "ecr_user_access_key_id" {
  value = module.iam.ecr_user_access_key_id
  sensitive = true
}

output "ecr_user_secret_access_key" {
  value = module.iam.ecr_user_secret_access_key
  sensitive = true
}