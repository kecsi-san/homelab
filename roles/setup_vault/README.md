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

The `vault` system user is created by `setup_users` with **UID 1008** (pinned to match the live server). The HashiCorp APT package also attempts to create a `vault` user — since it already exists, `adduser` skips creation and proceeds normally.

This matters for data migration: old server vault-data is owned by `vault:vault` (UID 1008). The new server vault user is also UID 1008, so rsync preserves correct ownership with no `chown` needed.

**Playbook order:** run `setup_users` before `setup_vault`.

## Vault bind address

Vault listens on `127.0.0.1:8200` (loopback only). Apache proxies HTTPS from `vault.kecskemethy.hu` and `vault.linuxbox.hu` to this address. Vault itself does not handle TLS.

The old live server bound to the VPC private IP (`172.30.2.246:8200`) — on the new server loopback is correct and more secure.

## Data migration from old server

The old server ran Vault v1.4.0 installed as a manual binary at `/opt/hashicorp/vault`. Migrate the file backend data:

```bash
# Run after setup_vault has created /opt/vault/data and vault user exists
rsync -av --chown=vault:vault old-ec2:/opt/hashicorp/vault-data/ new-ec2:/opt/vault/data/
```

Vault will upgrade the internal storage format on first startup after the data is in place. File backend format is forward-compatible — no manual migration steps needed between 1.4.x and current versions.

After migrating data, Vault will be in a **sealed** state and must be manually unsealed.

## First deploy (fresh instance, no data migration)

```bash
export VAULT_ADDR=http://127.0.0.1:8200
vault operator init          # prints 5 unseal keys + root token — save offline
vault operator unseal        # run 3 times with different keys
vault login <root-token>
```

## After data migration from old server

```bash
export VAULT_ADDR=http://127.0.0.1:8200
vault operator unseal        # run 3 times with the original unseal keys from 2020
```

The unseal keys and root token from the old server are required. They are **not managed by Ansible**.

## Variables

Defined in `inventory/group_vars/aws.yml`.

| Variable | Default | Description |
|----------|---------|-------------|
| `vault_version` | `""` | Package version to install, e.g. `1.19.3-1`; empty = latest |
| `vault_config_dir` | `/etc/vault.d` | Directory for `vault.hcl` (package default) |
| `vault_storage_path` | `/opt/vault/data` | File backend storage root |
| `vault_bind_addr` | `127.0.0.1:8200` | TCP listener — Apache proxies to this |
| `vault_api_addr` | `https://vault.{{ domain_name }}` | Public API URL (UI redirect target) |
| `vault_ui` | `true` | Enable built-in web UI |
| `vault_disable_mlock` | `false` | Set true only on kernels without `CAP_IPC_LOCK` |

## Tags

`--tags vault` — run only Vault tasks.
