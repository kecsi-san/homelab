# setup_users

Creates and configures named system users on the EC2 edge node.

## What it does

- Creates system users with pinned UIDs, GECOS, shell, and group memberships
- Deploys SSH authorized keys (additive — does not remove existing keys)
- Sets password hashes from secrets.yml (defaults to locked `!` if not provided)
- Optionally removes users while preserving home directories for data migration

## Why UIDs must be pinned

When migrating Maildirs and home data from the old server via `rsync --archive`, file ownership is stored as numeric UIDs in the filesystem. If the new server creates users with different UIDs, rsynced files will be owned by the wrong users. Pinning UIDs to match the live server eliminates the need for `chown -R` after migration.

Example layout — see `secrets.yml` for the actual `ec2_users` list and UID assignments:

| User  | UID  | GID  | Purpose               |
|-------|------|------|-----------------------|
| alice | 1000 | 1000 | Primary admin, sudo   |
| bob   | 1001 | 1001 | Mail-only             |
| vault | 1008 | 1008 | Vault service account |

Skip UIDs of deleted users from the old server entirely — don't reuse them, to avoid confusion.

## Playbook order

This role must run **before** `setup_email-server` (which creates Maildirs and references system users) and **after** any role that creates groups referenced in `ec2_users[].groups`:

- `adm`, `mail` — standard Debian base groups, always present
- `docker` — created by the Docker installation role (run that first)
- `sudo` — created by the `sudo` package (present after `ec2-prerequisite.yml`)

## Variables

`ec2_users` and `ec2_users_absent` are defined in `secrets.yml` (gitignored) — this data (real names, UIDs) is sensitive enough that it shouldn't be committed in plaintext.

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
alice_ssh_key: "ssh-ed25519 AAAA..."
alice_password_hash: "$6$salt$hash..."
bob_password_hash: "$6$salt$hash..."
```

## Tags

`--tags users` — run only user management tasks.
