# terraform/vault

Manages Vault *structure* — mounts, policies, auth methods — for the EC2/Ansible
secrets migration. Never manages secret *values*: Terraform state duplicates whatever
it manages in plaintext, and HashiCorp's own guidance is against `vault_kv_secret_v2`-style
resources for real secret content. See `docs/howtos/vault-secrets-architecture.md` for
the full design rationale.

## What this module creates

- `vault_mount.ec2` — KV v2 mount at `ec2/`
- `vault_policy.ec2_ansible_read` — read+list only on `ec2/data/*` and `ec2/metadata/*`
- `vault_policy.ec2_admin` — full CRUD on `ec2/*`
- `vault_auth_backend.approle` + `vault_approle_auth_backend_role.ansible` — machine auth for Ansible, bound to `ec2-ansible-read`
- `vault_auth_backend.userpass` — human auth method (the actual user is created manually, see step 3 below)
- `vault_mount.workstation` — KV v2 mount at `workstation/`, for personal/workstation secrets (SSH client config + keys, migrated from `../dotfiles`)
- `vault_policy.workstation_admin` — full CRUD on `workstation/*`, bound to the same userpass login as `ec2-admin`

## Setup

```bash
cp backend.conf.example backend.conf     # fill in your bucket name
cp terraform.tfvars.example terraform.tfvars   # fill in your Vault address
terraform init -backend-config=backend.conf
terraform validate
```

## Bootstrap steps (manual — deliberately not automated)

Run these in order, once, after `terraform apply`.

**1. Apply the module** (root token via `VAULT_TOKEN` — same trust level as the
root-equivalent AWS creds already in `secrets.yml` today):

```bash
export VAULT_ADDR=https://vault.kecskemethy.hu
export VAULT_TOKEN=<root token>
terraform apply
```

**2. Generate the AppRole secret_id** and store it alongside the `role_id` (from
`terraform output ansible_approle_role_id`) as two new keys in `secrets.yml`
(gitignored — reuses the existing secrets mechanism rather than inventing a new one):

```bash
vault write -f auth/approle/role/ansible/secret-id
# add to inventory/group_vars/all/secrets.yml:
#   vault_ansible_role_id: "<from terraform output>"
#   vault_ansible_secret_id: "<secret_id from this command>"
```

**3. Create your personal Vault login** (or update it, if it already exists, to add
`workstation-admin` alongside `ec2-admin`):

```bash
vault write auth/userpass/users/<your-username> password=<choose one> policies=ec2-admin,workstation-admin
```

**4. Migrate secret data** — one-time `vault kv put` calls, grouped to mirror
`secrets.yml`'s existing comment sections:

```bash
vault kv put ec2/aws-creds aws_access_key_id=... aws_secret_access_key=...
vault kv put ec2/duo duo_ikey=... duo_skey=... duo_api_host=...
vault kv put ec2/users ec2_users=@ec2_users.json   # or however ec2_users best serializes
vault kv put ec2/vhosts apache_certs=@apache_certs.json apache_vhosts=@apache_vhosts.json
vault kv put ec2/mail mailbox_users=@mailbox_users.json
```

The exact serialization for the list/dict-shaped values (`ec2_users`, `apache_certs`,
`apache_vhosts`, `mailbox_users`) needs a bit of care — KV v2 stores flat key/value pairs,
so nested structures go in as JSON strings. Decide the exact key layout when you do this
step; the Ansible lookup side (`inventory/group_vars/aws.yml`) needs to match whatever
you land on here.

**5. Migrate SSH client secrets** — `workstation/` uses a three-path layout: one config
list per machine, a generic key pool shared across machines, and a per-machine key pool
for keys that should stay strictly scoped to one machine (e.g. to let OpenSSH default
filenames like `id_ed25519` be reused across machines without colliding in Vault). See
`roles/configure_ssh-client/README.md` for the exact schema. Example:

```bash
# Generic pool -- reusable from any machine's config
vault kv put workstation/ssh-keys/generic/linuxbox2026 private_key=@$HOME/.ssh/linuxbox2026

# Host-specific pool -- only this machine's config may reference it
vault kv put workstation/ssh-keys/hosts/<your-wsl2-hostname>/id_ed25519 private_key=@$HOME/.ssh/id_ed25519

# Per-machine host list -- machine name is ansible_hostname (or inventory_hostname
# for remote targets like the EC2 edge node); each entry's key_scope picks which
# pool above its key_name comes from
vault kv put workstation/ssh-config/<your-wsl2-hostname> hosts=@ssh_client_hosts.json
```

## Rollout safety

Don't delete the existing values from `secrets.yml` until the Vault-lookup path in
`aws.yml` is verified working end-to-end (`ansible-playbook -i inventory/aws_hosts
playbooks/ec2-core.yml --check` resolving everything correctly). Removing the fallback
is a separate, later cleanup step.

## Verification

- `vault policy read ec2-ansible-read` / `vault auth list` — confirm the AppRole and policies exist as expected
- `vault write auth/approle/login role_id=... secret_id=...` — confirm it returns a token scoped to `ec2-ansible-read` only; try reading a path outside `ec2/*` and confirm denial
