terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend best-practice (example; uncomment/configure for remote state):
  # backend "s3" {
  #   bucket         = "your-remote-state-bucket"
  #   key            = "terraform-s3-site/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "your-remote-state-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region                      = var.aws_region
  access_key                  = var.use_localstack ? "test" : null
  secret_key                  = var.use_localstack ? "test" : null
  skip_credentials_validation = var.use_localstack
  skip_metadata_api_check     = var.use_localstack
  skip_requesting_account_id  = var.use_localstack
  s3_use_path_style           = var.use_localstack

  dynamic "endpoints" {
    for_each = var.use_localstack ? [1] : []
    content {
      s3 = "http://localstack:4566"
    }
  }
}
