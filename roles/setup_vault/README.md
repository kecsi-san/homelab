# setup_vault

Installs and configures HashiCorp Vault on the EC2 edge node.

## What it does

1. Adds the HashiCorp APT repository and GPG key
2. Installs the `vault` package (latest, or pinned via `vault_version`)
3. Optionally holds the package at the installed version (`apt-mark hold`)
4. Creates the storage directory at `vault_storage_path`
5. Deploys `vault.hcl` from template
6. Enables and starts the `vault` systemd service
7. Prints an initialization reminder on first deploy

## Relationship with setup_users

The `vault` system user is created by `setup_users` with **UID 1008** (pinned to match the live server). The HashiCorp APT package also attempts to create a `vault` user; since it already exists, `adduser` skips creation and proceeds normally.

This matters for data migration: the legacy server's `/opt/vault/data/` is owned by `vault:vault` (UID 1008). The new server's vault user is also UID 1008, so rsync preserves correct ownership with no `chown` needed.

**Playbook order:** run `setup_users` before `setup_vault`.

## Vault bind address

Vault listens on `127.0.0.1:8200` (loopback only). Apache proxies HTTPS from `vault.k*.hu` and `vault.l*.hu` to this address. Vault itself does not handle TLS.

The old live server bound to the VPC private IP (`172.30.2.246:8200`); on the new server loopback is correct and more secure.

## Data migration: two different Vaults, don't confuse them

There have been two Vault instances on the legacy box, and only one of them matters for a rebuild:

1. **Old, dead Vault (v1.4.0, manual binary at `/opt/hashicorp/vault`, data at `/opt/hashicorp/vault-data/`).** Unreachable since ~2020, nothing depended on it. **Deliberately not migrated**: the current Vault below was freshly initialized instead of trying to resurrect this one. Its data was simply left in place on the legacy box, unused.
2. **Current, live Vault (HashiCorp APT package, initialized 2026-07-04, data at `/opt/vault/data/`).** This is the one at `vault.k*.hu` that Ansible itself now depends on; `inventory/group_vars/aws_all.yml` sources `ec2_users`/`apache_vhosts`/`apache_certs`/`mailbox_users`/`duo_*`/AWS creds/DKIM backups from it via AppRole lookups (see `docs/howtos/vault-secrets-architecture.md`). **This one must be migrated before EIP cutover**: once the EIP swaps, `vault.k*.hu` resolves to the new instance's Vault, and if it's still empty, every Vault-sourced Ansible variable breaks (only the plaintext `secrets.yml` fallback values would keep working).

Migrate it as one of the last steps before cutover, so the copy is consistent:

```bash
# Run after setup_vault has created /opt/vault/data and vault user exists on the new box
ssh old-ec2 sudo systemctl stop vault   # stop the source for a consistent file-backend copy
rsync -av --chown=vault:vault old-ec2:/opt/vault/data/ new-ec2:/opt/vault/data/
# vault:vault is UID 1008 on both servers — ownership correct without chown,
# --chown is just an explicit safety net
```

After migrating data, Vault will be in a **sealed** state and must be manually unsealed with the **original 2026-07-04 unseal keys** (not the 2020 ones; there's nothing to unseal on that dead instance). See `docs/howtos/ec2-rebuild-plan.md`'s Phase 6 section for where this fits in the overall cutover sequence.

## First deploy (fresh instance, no data migration)

```bash
export VAULT_ADDR=http://127.0.0.1:8200
vault operator init          # prints 5 unseal keys + root token — save offline
vault operator unseal        # run 3 times with different keys
vault login <root-token>
```

## After data migration from the legacy box

```bash
export VAULT_ADDR=http://127.0.0.1:8200
vault operator unseal        # run 3 times with the original unseal keys from 2026-07-04
```

The unseal keys and root token from the legacy box's current Vault are required. They are **not managed by Ansible**.

## Variables

Defined in `inventory/group_vars/aws_all.yml`.

| Variable | Default | Description |
|----------|---------|-------------|
| `vault_version` | `""` | Package version to install, e.g. `1.19.3-1`; empty = latest |
| `vault_config_dir` | `/etc/vault.d` | Directory for `vault.hcl` (package default) |
| `vault_storage_path` | `/opt/vault/data` | File backend storage root |
| `vault_bind_addr` | `127.0.0.1:8200` | TCP listener; Apache proxies to this |
| `vault_api_addr` | `https://vault.{{ domain_name }}` | Public API URL (UI redirect target) |
| `vault_ui` | `true` | Enable built-in web UI |
| `vault_disable_mlock` | `false` | Set true only on kernels without `CAP_IPC_LOCK` |

## Tags

`--tags vault`: run only Vault tasks.
