# setup_restic-rest-server

Downloads the restic REST server binary from GitHub releases and runs it as
a systemd service, storing repositories on the volume `setup_nfs-backup`
carves out. Backend for all VolSync PVC backups (ntfy, gatus, mealie,
minecraft) on the k8s cluster.

## What it does

- Downloads and unarchives the `rest-server` release tarball (pinned
  version, `linux_amd64`)
- Installs the binary to `restic_rest_server_binary`
- Creates the repos directory (`restic_rest_server_path`)
- Templates a systemd unit and enables/starts it

## Variables

| Variable | Default | Description |
|----------|---------|--------------|
| `restic_rest_server_version` | `0.14.0` | Release version to download from `restic/rest-server` on GitHub |
| `restic_rest_server_listen` | `:8000` | Listen address/port |
| `restic_rest_server_path` | `/backups/restic-repos` | Directory holding all restic repos, one subdirectory per client |
| `restic_rest_server_binary` | `/usr/local/bin/rest-server` | Install path for the binary |

## Usage

```yaml
- role: setup_restic-rest-server
  tags: [restic-rest-server]
```

Run standalone, targeting `hppd600g6`, after `setup_nfs-backup`:

```bash
ansible-playbook playbooks/backup-nfs.yml
```

## Notes

- Runs with `--no-auth`, acceptable only because it's bound to the LAN via
  `restic_rest_server_path` sitting under the LAN-only NFS export from
  `setup_nfs-backup`; not exposed to the internet.
- Not version-pinned via Renovate (a manually-downloaded GitHub release
  binary, outside the `kube-gitops/` tree Renovate scans); bump
  `restic_rest_server_version` manually when needed.
- Each client namespace on the k8s cluster (`ntfy`, `gatus`, `mealie`,
  `minecraft`) points its VolSync `ReplicationSource` at
  `rest:http://192.168.1.52:8000/<name>`. The per-client path segment is
  created automatically by restic on first backup, not by this role.
