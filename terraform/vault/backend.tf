terraform {
  required_version = "~> 1.10"

  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.0"
    }
  }

  # Configured via: terraform init -backend-config=backend.conf
  # Copy backend.conf.example → backend.conf and fill in your values.
  # backend.conf is gitignored (contains S3 bucket name with AWS account ID).
  # Separate state from terraform/aws/ — different blast radius (Vault-admin
  # structure vs AWS infra), same S3 bucket, different key.
  backend "s3" {}
}
