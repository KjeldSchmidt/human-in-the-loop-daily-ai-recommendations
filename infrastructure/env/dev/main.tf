terraform {
  required_version = ">= 1.13.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.14"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  backend "s3" {
    # Same lab state bucket as tck-labs-base
    bucket       = "tck-labs-tfstate-6fd94603"
    key          = "noise-to-signal.dev.tfstate"
    region       = "eu-central-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = "eu-central-1"
}

module "web" {
  source = "../../modules/apprunner_web"

  project          = "noise-to-signal"
  environment      = "dev"
  db_name          = "noise_to_signal_dev"
  image_tag        = var.image_tag
  public_hostname  = var.public_hostname
  enable_apprunner = var.enable_apprunner
}

output "ecr_repository_url" {
  value = module.web.ecr_repository_url
}

output "service_url" {
  value = module.web.service_url
}

output "service_arn" {
  value = module.web.service_arn
}

output "app_secret_name" {
  value = module.web.app_secret_name
}

output "google_oauth_secret_name" {
  value = module.web.google_oauth_secret_name
}

output "db_name" {
  value = module.web.db_name
}

output "image_identifier" {
  value = module.web.image_identifier
}
