# Token is read ambiently from VAULT_TOKEN or ~/.vault-token — never a Terraform
# variable. This module manages structure only (mounts, policies, auth methods),
# never secret values, so it needs no secret-bearing tfvars at all.
provider "vault" {
  address = var.vault_address
}
