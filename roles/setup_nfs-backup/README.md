# setup_nfs-backup

Carves a logical volume from an existing volume group, formats it ext4,
mounts it, and exports it via NFS. Backing storage for the homelab's VolSync
PVC backups and the restic REST server (`setup_restic-rest-server`, run
right after this role in `playbooks/backup-nfs.yml`).

## What it does

- Installs `lvm2` and `nfs-kernel-server`
- Creates a logical volume (`community.general.lvol`) in an **existing**
  volume group; this role does not create the VG itself
- Formats the LV ext4
- Mounts it persistently at `nfs_backup_mount`
- Templates `/etc/exports`, reloads exports (`exportfs -ra`) on change
- Enables and starts `nfs-kernel-server`

## Variables

| Variable | Default | Description |
|----------|---------|--------------|
| `nfs_backup_vg` | `{{ inventory_hostname }}-vg` | Volume group name; must already exist |
| `nfs_backup_lv` | `backup` | Logical volume name |
| `nfs_backup_size` | `100g` | Logical volume size |
| `nfs_backup_mount` | `/backups` | Mount point |
| `nfs_backup_network` | `192.168.1.0/25` | Client network allowed to mount the NFS export |
| `nfs_backup_export_options` | `rw,sync,no_subtree_check,no_root_squash` | NFS export options |

## Usage

```yaml
- role: setup_nfs-backup
  tags: [nfs-backup]
```

Run standalone, targeting `hppd600g6`:

```bash
ansible-playbook playbooks/backup-nfs.yml
```

## Notes

- `nfs_backup_vg`'s default assumes an existing `<hostname>-vg` naming
  convention on the target host; override explicitly if the real VG name
  differs.
- Exported with `no_root_squash`, trusted LAN network only
  (`nfs_backup_network`), not internet-facing.
- The DNS alias `backups.kinet.local` to `192.168.1.52` (this host,
  `hppd600g6`) is managed separately by `configure_mikrotik-router`, not by
  this role.
