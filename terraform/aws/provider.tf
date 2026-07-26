provider "aws" {
  region = var.aws_region
}

# Token read ambiently from VAULT_TOKEN or ~/.vault-token — never a Terraform
# variable, same convention as terraform/vault/provider.tf. Used only to read
# the edge node's SSH bootstrap *public* key (ec2/ssh-edge-bootstrap-public);
# never the -private path — see docs/howtos/vault-secrets-architecture.md.
provider "vault" {
  address = var.vault_address
  # ec2-admin (the only policy this ambient token needs) has no
  # auth/token/create capability, so the provider's default ephemeral
  # child-token creation 403s. Reading ec2/* directly with the calling
  # token is sufficient — see terraform/vault/main.tf for the policy.
  skip_child_token = true
}
