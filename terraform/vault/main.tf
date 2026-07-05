# ec2/ — KV v2 mount holding everything currently in secrets.yml that's
# EC2/Ansible-specific (AWS creds, Duo, apache_certs/apache_vhosts, ec2_users,
# mailbox_users). See docs/howtos/vault-secrets-architecture.md.
resource "vault_mount" "ec2" {
  path        = "ec2"
  type        = "kv-v2"
  description = "EC2/Ansible secrets (migrated from secrets.yml)"

  options = {
    version = "2"
    type    = "kv-v2"
  }
}

# Read + list only on ec2/* — bound to the Ansible AppRole. Ansible never
# needs to write secrets, only read them at playbook run time.
resource "vault_policy" "ec2_ansible_read" {
  name = "ec2-ansible-read"

  policy = <<-EOT
    path "ec2/data/*" {
      capabilities = ["read", "list"]
    }
    path "ec2/metadata/*" {
      capabilities = ["read", "list"]
    }
  EOT
}

# Full CRUD on ec2/* for day-to-day `vault kv put/get` work — bound to a
# userpass login, not root.
resource "vault_policy" "ec2_admin" {
  name = "ec2-admin"

  policy = <<-EOT
    path "ec2/*" {
      capabilities = ["create", "read", "update", "delete", "list"]
    }
  EOT
}

# Machine auth for Ansible.
resource "vault_auth_backend" "approle" {
  type = "approle"
}

resource "vault_approle_auth_backend_role" "ansible" {
  backend        = vault_auth_backend.approle.path
  role_name      = "ansible"
  token_policies = [vault_policy.ec2_ansible_read.name]
}

# Human auth. The auth method itself is Terraform-managed; the actual user +
# password is created manually (a credential, kept out of Terraform per the
# architecture doc's decision to never let Terraform manage secret values) —
# see README.md for the bootstrap command.
resource "vault_auth_backend" "userpass" {
  type = "userpass"
}
