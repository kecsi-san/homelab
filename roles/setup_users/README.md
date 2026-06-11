# setup_users

Creates and configures named system users on the EC2 edge node.

## What it does

- Creates system users with pinned UIDs, GECOS, shell, and group memberships
- Deploys SSH authorized keys (additive — does not remove existing keys)
- Sets password hashes from secrets.yml (defaults to locked `!` if not provided)
- Optionally removes users while preserving home directories for data migration

## Why UIDs must be pinned

When migrating Maildirs and home data from the old server via `rsync --archive`, file ownership is stored as numeric UIDs in the filesystem. If the new server creates users with different UIDs, rsynced files will be owned by the wrong users. Pinning UIDs to match the live server eliminates the need for `chown -R` after migration.

**Live server UIDs (baseline 2026-06-11):**

| User  | UID  | GID  | Purpose               |
|-------|------|------|-----------------------|
| kecsi | 1000 | 1000 | Primary admin, sudo   |
| orsi  | 1001 | 1001 | Mail-only             |
| peter | 1005 | 1005 | Mail-only             |
| tamas | 1006 | 1006 | Mail-only             |
| vault | 1008 | 1008 | Vault service account |

UIDs 1002–1004 and 1007 are intentionally skipped (deleted users from old server — do not reuse to avoid confusion).

## Playbook order

This role must run **before** `setup_email-server` (which creates Maildirs and references system users) and **after** any role that creates groups referenced in `ec2_users[].groups`:

- `adm`, `mail` — standard Debian base groups, always present
- `docker` — created by the Docker installation role (run that first)
- `sudo` — created by the `sudo` package (present after `ec2-prerequisite.yml`)

## Variables

All defined in `inventory/group_vars/aws.yml`. Sensitive values go in `secrets.yml`.

| Variable         | Default | Description |
|------------------|---------|-------------|
| `ec2_users`      | `[]`    | List of user definitions (see below) |
| `ec2_users_absent` | `[]`  | Usernames to remove (home preserved) |

### User definition fields

| Field           | Required | Description |
|-----------------|----------|-------------|
| `name`          | yes      | Username |
| `uid`           | yes      | Numeric UID — always pin explicitly |
| `comment`       | no       | GECOS / full name |
| `groups`        | no       | Additional groups to append |
| `sudo`          | no       | If true, appends user to `sudo` group |
| `shell`         | no       | Login shell (default: `/bin/bash`; use `/bin/false` for service accounts) |
| `ssh_key`       | no       | SSH public key string — store in `secrets.yml` |
| `password_hash` | no       | SHA512-CRYPT hash — store in `secrets.yml`; omit to lock account |

### Generating a password hash

```bash
python3 -c "import crypt; print(crypt.crypt('yourpassword', crypt.mksalt(crypt.METHOD_SHA512)))"
```

## secrets.yml entries

```yaml
kecsi_ssh_key: "ssh-ed25519 AAAA..."
kecsi_password_hash: "$6$salt$hash..."
orsi_password_hash: "$6$salt$hash..."
peter_password_hash: "$6$salt$hash..."
tamas_password_hash: "$6$salt$hash..."
```

## Tags

`--tags users` — run only user management tasks.
