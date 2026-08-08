# setup_users

Creates and configures named system users on the EC2 edge node.

## What it does

- Creates system users with pinned UIDs, GECOS, shell, and group memberships
- Deploys SSH authorized keys (additive; does not remove existing keys)
- Sets passwords from a plaintext value in Vault, hashed at apply time (defaults to locked `!` if not provided)
- Optionally removes users while preserving home directories for data migration

## Why UIDs must be pinned

When migrating Maildirs and home data from the old server via `rsync --archive`, file ownership is stored as numeric UIDs in the filesystem. If the new server creates users with different UIDs, rsynced files will be owned by the wrong users. Pinning UIDs to match the live server eliminates the need for `chown -R` after migration.

Example layout; see `secrets.yml` for the actual `ec2_users` list and UID assignments:

| User  | UID  | GID  | Purpose               |
|-------|------|------|-----------------------|
| alice | 1000 | 1000 | Primary admin, sudo   |
| bob   | 1001 | 1001 | Mail-only             |
| vault | 1008 | 1008 | Vault service account |

Skip UIDs of deleted users from the old server entirely; don't reuse them, to avoid confusion.

## Playbook order

This role must run **before** `setup_email-server` (which creates Maildirs and references system users) and **after** any role that creates groups referenced in `ec2_users[].groups`:

- `adm`, `mail`: standard Debian base groups, always present
- `sudo`: created by the `sudo` package (present after `ec2-prerequisite.yml`)

Any group listed in `ec2_users[].groups` must already exist on the host; `ansible.builtin.user` doesn't create groups itself, only appends users to existing ones. A group reference for software that isn't actually installed (e.g. a since-decommissioned `docker`) will fail this task outright.

## Variables

`ec2_users` and `ec2_users_absent` are defined in `secrets.yml` (gitignored); this data (real names, UIDs) is sensitive enough that it shouldn't be committed in plaintext.

| Variable         | Default | Description |
|------------------|---------|-------------|
| `ec2_users`      | `[]`    | List of user definitions (see below) |
| `ec2_users_absent` | `[]`  | Usernames to remove (home preserved) |

### User definition fields

| Field           | Required | Description |
|-----------------|----------|-------------|
| `name`          | yes      | Username |
| `uid`           | yes      | Numeric UID; always pin explicitly |
| `comment`       | no       | GECOS / full name |
| `groups`        | no       | Additional groups to append |
| `sudo`          | no       | If true, appends user to `sudo` group |
| `shell`         | no       | Login shell (default: `/bin/bash`; use `/bin/false` for service accounts) |
| `ssh_key`       | no       | SSH public key string; store in `secrets.yml` |
| `password`      | no       | **Plaintext**: store in Vault (`ec2/users`), not `secrets.yml`; hashed by this role at apply time, never written to disk as plaintext; omit to lock the account |

### Why plaintext, in Vault

For this host, SSH is key-only (password auth disabled); `password` only gates PAM-based logins for things like IMAP/SMTP-AUTH over SSL. Storing the plaintext in Vault (rather than a pre-computed hash) means a forgotten password is *recoverable* from Vault, not just resettable, which matters more here than an extra layer of hash-only defense would. The role hashes it (`password_hash('sha512')` filter) as part of templating the `ansible.builtin.user` call; the plaintext value itself is never written to any file on the target host.

`secrets.yml`'s `ec2_users` entries reference this indirectly (e.g. `password: "{{ kecsi_password | default(omit) }}"`) purely as a fallback placeholder pattern; the real values live in Vault's `ec2/users` secret alongside the rest of that user's data, not as separate `secrets.yml` variables.

## Tags

`--tags users`: run only user management tasks.
