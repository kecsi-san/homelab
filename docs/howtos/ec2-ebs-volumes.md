# EC2 EBS Volume Plan

Storage design for the new EC2 edge node (email + web server).

## Design Principles

- **Mount directly at native paths** — no symlinks, no `/srv` workaround, no indirection
- **Each volume grows independently** — resize mail storage without touching web or OS
- **Services write to their natural locations** — Apache to `/var/www`, Dovecot to `/home`, logs to `/var/log`

---

## Volume Layout

| # | Mount | Size | Type | What lives there |
|---|---|---|---|---|
| 1 | `/` | 20 GB | gp3 | OS, packages, configs (`/etc`), small service state (`/opt`, `/var/lib/rspamd`, `/var/lib/vault`) |
| 2 | `/home` | 40 GB | gp3 | User Maildirs — 5.6 GB today (4 users), room for growth + future Bichon email archive |
| 3 | `/var/www` | 20 GB | gp3 | Apache web content — 1.15 GB today (linuxbox.hu 852 MB, kecskemethy.hu 295 MB) |
| 4 | `/var/log` | 10 GB | gp3 | All system and service logs — isolated so log growth never kills root or services |

**Total: 90 GB → ~$7.92/month** (gp3 at $0.088/GB-month, eu-west-1, checked via AWS Pricing API 2026-07-11)

---

## Current Baseline (measured 2026-06-11)

| Path | Current size | Notes |
|---|---|---|
| `/` (root volume) | 14 GB used / 25 GB | OS + all services |
| `/home/kecsi/Maildir` | 5.2 GB | Largest mailbox, grows ~0.5–1 GB/year |
| `/home/peter/Maildir` | 234 MB | |
| `/home/orsi/Maildir` | 102 MB | |
| `/home/tamas/Maildir` | 51 MB | |
| `/var/www/linuxbox.hu` | 852 MB | |
| `/var/www/kecskemethy.hu` | 295 MB | Includes kepek static files (served from S3) |
| `/var/log` | 3.2 GB | Large due to historical accumulation — logrotate controls ongoing growth |
| `/opt/hashicorp` | 172 MB | HashiCorp Vault binary + data |
| `/var/lib/rspamd` | 91 MB | DKIM keys, bayes, greylisting state |

---

## What Not to Do (lessons from current server)

The current server uses a single `/srv` EBS volume as a dumping ground, with symlinks pointing back to OS paths:

```
/srv/home      → /home
/srv/lib       → /usr/lib
/srv/opt       → various
/srv/usr_src   → /usr/src equivalent
/srv/var_lib   → /var/lib equivalent
```

This creates confusion about where data actually lives and makes it hard to reason about disk usage, resize volumes, or apply OS-level tools cleanly. **The new server will not use this pattern.**

---

## Terraform

**Implemented 2026-07-11.** EBS volumes are declared as separate `aws_ebs_volume` + `aws_volume_attachment` resources (not root block device) so they can be resized independently.

Implementation lives in the reusable `terraform/modules/ec2` module (not a dedicated `terraform/aws/ec2/`, as originally sketched here — the module is shared between the legacy instance and this one). The `data_volumes` variable takes this exact layout; the module call is in `terraform/aws/main.tf` under `module "ec2_edge"`:

```hcl
data_volumes = {
  "/dev/sdf" = { size = 40, type = "gp3", encrypted = true, name = "edge.kecskemethy.net-home" }
  "/dev/sdg" = { size = 20, type = "gp3", encrypted = true, name = "edge.kecskemethy.net-www" }
  "/dev/sdh" = { size = 10, type = "gp3", encrypted = true, name = "edge.kecskemethy.net-log" }
}
```

The legacy instance (`module "ec2"`) keeps its original inline-`ebs_block_device` layout via a separate `legacy_extra_volumes` variable on the same module — unencrypted, single `/dev/sdf` 32GB `standard` volume, matching its real imported state. Do not change that call; it mirrors what's actually running on `i-04dba0d34a28a972d` today.

Verified via `terraform plan`: adding the new instance produces zero unwanted diff against the legacy instance (only a pre-existing stale-tag correction, unrelated to this layout work).

---

## OS-Level Setup (Ansible)

**Status: not yet implemented (2026-07-11).** Terraform now creates and attaches the 4 volumes (see above), but nothing formats or mounts them yet. Needs an `ec2-storage.yml` playbook (or a `configure_fstab` task in `ec2-core.yml`) run before any other Phase 6 role, since `setup_users`/`setup_email-server`/`setup_apache2` all write to `/home`/`/var/www` immediately.

Mount points are created and `/etc/fstab` entries written by an `ec2-storage.yml` playbook (or a `configure_fstab` task in `ec2-core.yml`) before any other role runs:

```yaml
- name: Create mount points
  ansible.builtin.file:
    path: "{{ item }}"
    state: directory
  loop:
    - /home
    - /var/www
    - /var/log

- name: Mount EBS volumes
  ansible.posix.mount:
    path: "{{ item.path }}"
    src: "{{ item.device }}"
    fstype: ext4
    opts: defaults,nofail
    state: mounted
  loop:
    - { path: /home,     device: /dev/sdf }
    - { path: /var/www,  device: /dev/sdg }
    - { path: /var/log,  device: /dev/sdh }
```

> **Note:** Device names (`/dev/sdf` etc.) are the AWS API names. The kernel may see them as `/dev/nvme1n1` etc. Use UUID-based fstab entries in practice (`blkid` after attach).
