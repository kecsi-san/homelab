terraform {
  required_version = "~> 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }

  # Configured via: terraform init -backend-config=backend.conf
  # Copy backend.conf.example → backend.conf and fill in your values.
  # backend.conf is gitignored (contains S3 bucket name with AWS account ID).
  backend "s3" {}
}
