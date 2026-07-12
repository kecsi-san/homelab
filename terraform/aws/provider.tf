provider "aws" {
  region = var.aws_region
}

# Token read ambiently from VAULT_TOKEN or ~/.vault-token — never a Terraform
# variable, same convention as terraform/vault/provider.tf. Used only to read
# the edge node's SSH bootstrap *public* key (ec2/ssh-edge-bootstrap-public);
# never the -private path — see docs/howtos/vault-secrets-architecture.md.
provider "vault" {
  address = var.vault_address
}
