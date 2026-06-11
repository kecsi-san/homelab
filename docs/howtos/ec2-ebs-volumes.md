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

**Total: 90 GB → ~$7.20/month** (gp3 at $0.08/GB/month, eu-west-1)

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

EBS volumes are declared as separate `aws_ebs_volume` + `aws_volume_attachment` resources (not root block device) so they can be resized independently.

See `terraform/aws/ec2/` for implementation.

```hcl
# example — home volume
resource "aws_ebs_volume" "mail" {
  availability_zone = aws_instance.ec2.availability_zone
  size              = 40
  type              = "gp3"
  encrypted         = true
  tags = { Name = "ec2-mail" }
}

resource "aws_volume_attachment" "mail" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.mail.id
  instance_id = aws_instance.ec2.id
}
```

---

## OS-Level Setup (Ansible)

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
