# setup_restic-backup

Backs up directories to a restic repository on a schedule. One systemd service runs a small script, a timer starts it.

## What it does

- Installs `restic`.
- Writes `/etc/restic/env` (mode 0600) with the repository and password.
- Installs `/usr/local/sbin/restic-backup`, which backs up each directory in `restic_backup_dirs` as its own snapshot with the tag `restic_backup_tag`.
- Installs and enables `restic-backup.timer` (default 23:00 plus up to 15 minutes of random delay, `Persistent=true` so a run missed while the host was off happens at the next boot).
- Optionally follows the backup with `check`, `forget --keep-daily N` and `prune`.

The role does not run a backup itself and does not initialize a repository. Point it at an existing one, or run `restic init` once by hand.

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `restic_backup_enabled` | `false` | Playbooks run the role only when true |
| `restic_backup_repository` | none | Repository URL, for example `s3:s3.amazonaws.com/example-bucket/restic` (required) |
| `restic_backup_password` | none | Repository password (required, keep it in Vault) |
| `restic_backup_dirs` | `/etc`, `/root`, `/home` | Directories to back up |
| `restic_backup_tag` | `fs` | Tag on the snapshots |
| `restic_backup_extra_args` | `[]` | Extra arguments for `restic backup` |
| `restic_backup_schedule` | `*-*-* 23:00:00` | systemd calendar expression |
| `restic_backup_random_delay` | `15min` | Random delay added to the schedule |
| `restic_backup_maintenance` | `false` | Run check, forget and prune after the backup |
| `restic_backup_keep_daily` | `30` | Daily snapshots kept by `forget` |

## Notes

- With S3 and an instance profile, the host needs no access keys. The profile must allow read, write and delete on the repository prefix.
- Several hosts can share one repository, because restic records the host name in each snapshot. Run maintenance on one host only: `prune` takes an exclusive lock.
- The service gets its own cache directory (`/var/cache/restic`, created by systemd), because a system service has no `$HOME` for restic's default cache.
- A newer restic keeps writing to a repository in the old format. It does not upgrade the format unless you run `restic migrate`, and older clients on other hosts cannot read an upgraded repository.
- Check the last run with `systemctl status restic-backup.service` and `journalctl -u restic-backup.service`. List snapshots with `sudo bash -c 'set -a; . /etc/restic/env; restic snapshots'`.

## Usage

```yaml
- name: Setup restic backups
  ansible.builtin.import_role:
    name: setup_restic-backup
  become: true
  when: restic_backup_enabled | default(false)
  tags:
    - restic
```
