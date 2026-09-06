output "ansible_approle_role_id" {
  description = "AppRole role_id for Ansible auth (stable, not sensitive — safe to output). Pair with a generated secret_id (see README.md) and store both in secrets.yml as vault_ansible_role_id / vault_ansible_secret_id."
  value       = vault_approle_auth_backend_role.ansible.role_id
}

output "eso_homelab_approle_role_id" {
  description = "AppRole role_id for k8s's External Secrets Operator (stable, not sensitive — safe to output). Pair with a generated secret_id and seal both into a SealedSecret bootstrapping ESO's SecretStore — see docs/howtos/vault-secrets-architecture.md."
  value       = vault_approle_auth_backend_role.eso.role_id
}

output "eso_k3s_approle_role_id" {
  description = "AppRole role_id for k3s's External Secrets Operator (stable, not sensitive — safe to output). Same bootstrap pattern as eso_homelab_approle_role_id, scoped to homelab/k3s/* only."
  value       = vault_approle_auth_backend_role.eso_k3s.role_id
}
