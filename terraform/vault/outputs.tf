output "ansible_approle_role_id" {
  description = "AppRole role_id for Ansible auth (stable, not sensitive — safe to output). Pair with a generated secret_id (see README.md) and store both in secrets.yml as vault_ansible_role_id / vault_ansible_secret_id."
  value       = vault_approle_auth_backend_role.ansible.role_id
}
