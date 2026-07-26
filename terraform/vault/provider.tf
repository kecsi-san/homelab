# Token is read ambiently from VAULT_TOKEN or ~/.vault-token — never a Terraform
# variable. This module manages structure only (mounts, policies, auth methods),
# never secret values, so it needs no secret-bearing tfvars at all.
provider "vault" {
  address = var.vault_address
  # See terraform/aws/provider.tf for why this is needed: the provider's
  # default ephemeral child-token creation 403s unless a policy explicitly
  # grants auth/token/create, which none here do.
  skip_child_token = true
}
