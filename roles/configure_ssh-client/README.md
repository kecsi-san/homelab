# configure_ssh-client

Templates `~/.ssh/config` from Vault, and fetches only the private keys that
machine's config actually references — not the whole key pool. Migrated from
the old `../dotfiles` `.ssh/config` (see homelab `TODO.md` "Dotfiles migration").

## Vault layout: three paths

This role runs on multiple different machines (WSL2 home, macOS work laptop,
EC2 edge node), each needing a different subset of SSH hosts and keys —
never all keys copied to all machines.

- `workstation/ssh-config/<machine>` — one path per machine (keyed by
  `ansible_hostname`, or `inventory_hostname` for a remote target like the
  EC2 edge node), holding a `hosts` field: a JSON list of host entries.
- `workstation/ssh-keys/generic/<key-name>` — the shared pool. Keys meant to
  be referenced from more than one machine's config, e.g.
  `workstation/ssh-keys/generic/linuxbox2026`.
- `workstation/ssh-keys/hosts/<machine>/<key-name>` — keys strictly scoped to
  one machine. Lets you keep OpenSSH's own default-identity filenames (like
  `id_ed25519`) without any collision risk, since every machine has its own
  namespace here — unlike the generic pool, which is shared and would clash
  if two machines both tried to store a key literally named `id_ed25519`.

Each host entry's `key_scope` field picks which pool its `key_name` comes
from: `generic` (default, omit the field entirely for this) or `host`. The
*local* filename (`~/.ssh/{{ key_name }}`) is identical either way — only the
Vault source path differs.

Example `hosts` value for `workstation/ssh-config/<your-wsl2-hostname>`:

```json
[
  {
    "host": "linuxbox linuxbox.hu 52.48.130.44",
    "hostname": "linuxbox.hu",
    "user": "kecsi",
    "key_name": "linuxbox2026",
    "port": 22,
    "control_master": "auto",
    "control_path": "/run/user/%i/ssh-%C",
    "control_persist": "30m"
  },
  {
    "host": "800g5 800g61 800g62 600g6 192.168.1.18 192.168.1.34 192.168.1.36 192.168.1.52",
    "user": "kecsi",
    "key_name": "id_ed25519",
    "key_scope": "host"
  }
]
```

`host` can hold multiple space-separated aliases in one string (rendered
as-is into the `Host` line). `hostname`, `port`, `control_master`,
`control_path`, `control_persist`, and `extra_lines` (a list of raw
additional SSH config lines, e.g. for `PubkeyAcceptedKeyTypes`) are all
optional per entry — omit any that don't apply; omitting `hostname` lets a
multi-alias `Host` line resolve each alias literally instead of forcing them
all to one target. `control_path` should point at Linux tmpfs
(`/run/user/%i/...`), not a Windows-mounted (DrvFs/9p) path, on WSL2 — DrvFs
doesn't support Unix domain sockets.

Note: `ControlMaster`/`ControlPath`/`ControlPersist` here only benefit your
own interactive `ssh`/`scp`/`rsync` commands. Ansible uses its own separate
`ControlPath`/`ControlPersist` (under `~/.ansible/cp/`) regardless of what's
configured here — the two never share a connection.

## What it does

1. Fetches `workstation/ssh-config/{{ ssh_client_machine_name }}` — this
   machine's host list.
2. For each entry, fetches its key from `workstation/ssh-keys/generic/<key_name>`
   or `workstation/ssh-keys/hosts/{{ ssh_client_machine_name }}/<key_name>`
   (per that entry's `key_scope`) and writes it to `~/.ssh/{{ key_name }}`
   (`mode: '0600'`, `no_log: true` so key material never hits Ansible's logs).
3. Derives each key's public counterpart locally (`ssh-keygen -y`, not stored
   in Vault — public keys aren't secret) and writes `~/.ssh/{{ key_name }}.pub`
   (`mode: '0644'`). Used by e.g. `configure_git`'s SSH-format commit signing.
4. Templates `~/.ssh/config` from the host list, one `Host` block per entry.

## Variables

| Variable | Source | Description |
|----------|--------|--------------|
| `ssh_client_machine_name` | `defaults/main.yml` | Vault config-path segment for this machine; defaults to `ansible_hostname` so it differs automatically per machine — override only if you need something other than the real hostname |
| `vault_workstation_lookup_args` | `inventory/group_vars/local.yml` | Vault lookup args (`url`, `engine_mount_point: workstation`, auth via the cached `~/.vault-token`) |

## Usage

```yaml
- name: Configure SSH client
  ansible.builtin.import_role:
    name: configure_ssh-client
  become: false
  tags:
    - ssh-client
```

## Prerequisites

- `vault login` (or equivalent) run beforehand so `~/.vault-token` exists and
  is valid — this role uses your existing session, it doesn't authenticate on
  its own.
- The Vault entries for this specific machine (`ssh-config/<hostname>`) and
  every key it references (`ssh-keys/generic/<key-name>` or
  `ssh-keys/hosts/<hostname>/<key-name>`, per each entry's `key_scope`) must
  already exist — see `terraform/vault/README.md` step 5. The role fails
  loudly (missing secret) rather than silently rendering an empty config if
  they don't exist yet.

## Notes

- Every run fully re-renders `~/.ssh/config` from whatever's in Vault at that
  moment — no stale entries can linger the way they could with an
  append-only approach.
- No AppRole/machine-auth needed: this only ever runs interactively on your
  own workstation, so it reuses your own userpass session instead of
  provisioning separate credentials.
