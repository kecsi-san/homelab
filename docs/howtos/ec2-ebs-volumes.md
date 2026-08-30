# EC2 EBS Volume Plan

Storage design for the new EC2 edge node (email + web server).

## Design Principles

- **Mount directly at native paths**: no symlinks, no `/srv` workaround, no indirection
- **Each volume grows independently**: resize mail storage without touching web or OS
- **Services write to their natural locations**: Apache to `/var/www`, Dovecot to `/home`, logs to `/var/log`

---

## Volume Layout

| # | Mount | Size | Type | What lives there |
|---|---|---|---|---|
| 1 | `/` | 20 GB | gp3 | OS, packages, configs (`/etc`), small service state (`/opt`, `/var/lib/rspamd`, `/var/lib/vault`) |
| 2 | `/home` | 40 GB | gp3 | User Maildirs, 5.6 GB today (4 users), room for growth + future Bichon email archive |
| 3 | `/var/www` | 20 GB | gp3 | Apache web content, 1.15 GB today (l*.hu 852 MB, k*.hu 295 MB) |
| 4 | `/var/log` | 10 GB | gp3 | All system and service logs, isolated so log growth never kills root or services |

**Total: 90 GB → ~$7.92/month** (gp3 at $0.088/GB-month, eu-west-1, checked via AWS Pricing API 2026-07-11)

---

## Current Baseline (measured 2026-06-11)

| Path | Current size | Notes |
|---|---|---|
| `/` (root volume) | 14 GB used / 25 GB | OS + all services |
| `/home/<u1>/Maildir` | 5.2 GB | Largest mailbox, grows ~0.5-1 GB/year |
| `/home/<u2>/Maildir` | 234 MB | |
| `/home/<u3>/Maildir` | 102 MB | |
| `/home/<u4>/Maildir` | 51 MB | |
| `/var/www/<d1>.hu` | 852 MB | |
| `/var/www/<d2>.hu` | 295 MB | Includes kepek static files (served from S3) |
| `/var/log` | 3.2 GB | Large due to historical accumulation; logrotate controls ongoing growth |
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

Implementation lives in the reusable `terraform/modules/ec2` module (not a dedicated `terraform/aws/ec2/`, as originally sketched here; the module is shared between the legacy instance and this one). The `data_volumes` variable takes this exact layout; the module call is in `terraform/aws/main.tf` under `module "ec2_edge"`:

```hcl
data_volumes = {
  "/dev/sdf" = { size = 40, type = "gp3", encrypted = true, name = "edge.<d>.net-home" }
  "/dev/sdg" = { size = 20, type = "gp3", encrypted = true, name = "edge.<d>.net-www" }
  "/dev/sdh" = { size = 10, type = "gp3", encrypted = true, name = "edge.<d>.net-log" }
}
```

The legacy instance (`module "ec2"`) keeps its original inline-`ebs_block_device` layout via a separate `legacy_extra_volumes` variable on the same module: unencrypted, single `/dev/sdf` 32GB `standard` volume, matching its real imported state. Do not change that call; it mirrors what's actually running on `i-04dba0d34a28a972d` today.

Verified via `terraform plan`: adding the new instance produces zero unwanted diff against the legacy instance (only a pre-existing stale-tag correction, unrelated to this layout work).

---

## OS-Level Setup (cloud-init, not Ansible)

**Status: implemented in Terraform, not yet applied (2026-07-12).** `terraform validate` passes cleanly. Terraform creates and attaches the 4 volumes (see above); formatting and mounting them happens via cloud-init `user_data` on `ec2_edge`, at first boot, before Ansible ever connects, not a separate `ec2-storage.yml` playbook as originally sketched. This also removes the ordering hazard (`setup_users`/`setup_email-server`/`setup_apache2` writing to `/home`/`/var/www` before they're mounted): cloud-init's `disk_setup`/`mounts` modules run before the `users-groups` module in the default module order, so the volumes are mounted before `kecsi`'s home directory is even created.

Devices are identified via `/dev/disk/by-id/nvme-Amazon_Elastic_Block_Store_<volume-id-no-dashes>` (deterministic, keyed off each `aws_ebs_volume`'s own ID) rather than matching by disk size or assuming a fixed `/dev/sdX`/`/dev/nvme1n1` mapping (not reliable on Nitro instances without AWS's udev helper, which the stock Debian AMI doesn't ship). This requires `terraform/modules/ec2` to source the data volumes' `availability_zone` from a `data "aws_subnet"` lookup instead of `aws_instance.this.availability_zone`, so the volumes don't depend on the instance and the instance's own `user_data` can reference its volumes' IDs.

Sketch of the generated cloud-config (rendered via `templatefile()` inside the module):

```yaml
#cloud-config
fs_setup:
  - label: home
    filesystem: ext4
    device: /dev/disk/by-id/nvme-Amazon_Elastic_Block_Store_<home-volume-id>
    partition: none
  - label: www
    filesystem: ext4
    device: /dev/disk/by-id/nvme-Amazon_Elastic_Block_Store_<www-volume-id>
    partition: none
  - label: log
    filesystem: ext4
    device: /dev/disk/by-id/nvme-Amazon_Elastic_Block_Store_<log-volume-id>
    partition: none

mounts:
  - [ "/dev/disk/by-id/nvme-Amazon_Elastic_Block_Store_<home-volume-id>", /home, ext4, "defaults,nofail" ]
  - [ "/dev/disk/by-id/nvme-Amazon_Elastic_Block_Store_<www-volume-id>", /var/www, ext4, "defaults,nofail" ]
  - [ "/dev/disk/by-id/nvme-Amazon_Elastic_Block_Store_<log-volume-id>", /var/log, ext4, "defaults,nofail" ]
```

This is combined in the same `user_data` with the `system_info.default_user.name: kecsi` rename; see `docs/howtos/ec2-rebuild-plan.md`'s Phase 6 design-decisions section for the full picture (SSH bootstrap key, Vault storage, rename rationale).
