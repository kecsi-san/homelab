# EC2 Edge Node Rebuild Plan

## Context

**The EC2 edge node currently running (`i-04xxx72d`, `52.xxx.44`) is still the original instance manually configured since 2016**: it was brought under Terraform management via `terraform import` (security group, EIP, Route53), not replaced. Its EC2 `LaunchTime` shows a 2026-06 date, but that just reflects a reboot after an in-place Debian Bookworm → Trixie upgrade, not instance creation. Don't mistake it for a fresh box.

**Plan history:** The original idea was to fully reverse-engineer this instance's configuration and apply the resulting Ansible + Terraform code *in place*, converging the live box itself into a fully codified, idempotent state without replacing hardware. This was investigated directly in a Claude Code session running on the instance itself. That investigation found enough accumulated manual drift from ~10 years of hands-on changes: legacy SSH keys from multiple eras, mail-stack components later found redundant and replaced (OpenDKIM + Postgrey + SpamAssassin → Rspamd), installed-but-unused software (Docker with no containers), decommissioned services left behind (Nextcloud, MariaDB), and unserved static file leftovers. Safely reconciling it all in place via Ansible wasn't realistic. **That approach was abandoned.**

The current plan instead: build Ansible roles that capture the *desired* state (validated by reading the live box's config, not by running Ansible against it), provision a **new** EC2 instance, apply the full role set there fresh, migrate only the data that's actually valuable (DKIM keys, mailboxes, website content, Vault data, see below), swap the EIP, then decommission whatever remains on the old instance.

**Exception (2026-07-04):** Two narrow, self-contained fixes were applied directly to the still-live legacy instance ahead of the rebuild, rather than waiting for cutover: a `setup_email-server` cron bug fix (dovecot-fts `%` escaping), and a `configure_duo-ssh` + `setup_aws-ssm-agent` migration of SSH MFA from `ForceCommand login_duo` to PAM-based `pam_duo.so` (the old ForceCommand setup was making routine Ansible/ops work on this box impractically slow, one Duo push per SSH session). These are operational improvements to the box as it exists today; they are **not** progress toward Phase 6 below, and the new instance build should still apply these same roles fresh rather than assume anything carries over.

**Security fix (2026-07-04):** `inventory/group_vars/aws.yml` had `ec2_users`, `apache_certs`, `apache_vhosts`, `apache_server_admin`, and `vault_api_addr` committed in plaintext: real full names, UIDs, domain/vhost topology, and an internal Vault proxy target, directly violating this repo's own documented secrets.yml/vars.yml split. Moved into `secrets.yml` (gitignored). Also added `configure_ssh-hardening` (see Roles Summary below).

**Phase 6 progress (2026-07-11):** Terraform side of step 1 is done: `module "ec2_edge"` + `module "eip_edge"` in `terraform/aws/main.tf` provision the new instance (`edge.<d>.net`) alongside the legacy one, same SG rule set, plus the 4-volume EBS layout from `docs/howtos/ec2-ebs-volumes.md` (root gp3 20GB + `/home` 40GB + `/var/www` 20GB + `/var/log` 10GB, all encrypted, as standalone resizable `aws_ebs_volume`s). Verified via `terraform plan` that this is purely additive, zero unwanted changes to the live legacy instance. **Not yet applied**: plan is reviewed, `terraform apply` deliberately deferred to run manually.

**Phase 6 design decisions (2026-07-12):** Bootstrap sequencing, the admin→`kecsi` rename, and the EBS mount step are now fully designed **and implemented in Terraform** (`terraform validate` clean; `terraform apply` deliberately not run):

- **First-boot config moves to cloud-init, not Ansible.** The `ec2_edge` module call gains a generated `user_data` (cloud-config) that does two things at first boot, before any playbook ever connects:
  1. **User rename**: `system_info.default_user.name: kecsi` instead of Debian's default `admin`. Cloud-init merges this with the distro's default sudo/group/shell config for the bootstrap user, so `kecsi` comes up with the same NOPASSWD sudo the `admin` user would have had, just under the right name from the start. Avoids a fragile post-hoc rename (Ansible would be renaming the very account it's SSH'd in as, plus a UID clash against `setup_users`' hardcoded `uid: 1000` for `kecsi`). `setup_users`' existing `kecsi` (uid 1000) entry then just idempotently converges extra groups/keys on top; no role changes needed. One thing to verify post-boot: that cloud-init actually assigned UID 1000 (expected on a fresh AMI, but check with `id kecsi` before running `setup_users`).
  2. **EBS volume format + mount**: supersedes the originally-sketched `ec2-storage.yml` playbook idea; cloud-init's `disk_setup`/`fs_setup`/`mounts` modules handle it directly, before Ansible connects at all. Devices are identified via `/dev/disk/by-id/nvme-Amazon_Elastic_Block_Store_<volume-id-no-dashes>` (deterministic, keyed off each `aws_ebs_volume`'s own ID) rather than matching by disk size, immune to a future resize accidentally colliding two volumes' sizes. Requires a small refactor in `terraform/modules/ec2`: the data volumes currently get their `availability_zone` from `aws_instance.this.availability_zone`, which makes them depend on the instance; switching that to a `data "aws_subnet"` lookup removes the circular dependency, so the instance's own `user_data` can reference its volumes' IDs. Only `ec2_edge` gets `user_data`; the legacy `module "ec2"` call is untouched (verify via `terraform plan`, zero diff expected on the legacy instance, same as the original EBS-layout change).

- **Dedicated SSH keypair for the new box, escrowed in Vault, not another loose `.pem`.** A new ed25519 keypair (`<key>2026`) has already been generated, replacing the shared decade-old `<key>2016.pem` for this instance. Plan:
  1. New `aws_key_pair` Terraform resource registers `<key>2026`'s **public** key, used as `key_name` for `ec2_edge` only (legacy instance keeps its own `key_pair_name`).
  2. Public and private halves are stored as **two separate** Vault KV entries: `ec2/ssh-edge-bootstrap-public` (public key only) and `ec2/ssh-edge-bootstrap-private` (private key only, human-access only), deliberately not combined into one entry. Reason: `terraform/aws` gains the `hashicorp/vault` provider (ambient token, same convention as `terraform/vault/provider.tf`) so the `aws_key_pair` resource can read the public key directly from Vault via a data source. A Terraform data source's entire `data` map lands in state, even for fields you don't reference, so if public and private key shared one Vault path, the private key would leak into `terraform/aws`'s state via that read alone. Splitting the paths keeps Terraform from ever touching the private key. This is a read, not a write, so it doesn't conflict with `vault-secrets-architecture.md`'s decision that Terraform never manages secret *values*: Terraform still never creates/updates any secret content, only consumes an already-existing one.
  3. `vault kv put` for both paths is a manual, one-time step (same convention as the other EC2 secrets already documented there).
  4. `ssh-add ~/.ssh/<key>2026` (fetched from Vault once) locally before the first `ec2-prerequisite.yml` run: that's how Ansible connects the very first time, before `configure_ssh` deploys the regular workstation key.

- Terraform-generated `inventory/aws_hosts`'s `[aws_edge]` line needs `ansible_user=kecsi`, not the shared `var.admin_user` (which stays `admin` for the legacy box); a new `edge_ssh_user` variable, default `"kecsi"`.

Still missing before step 2 (running the playbooks) can happen: the two manual `vault kv put` calls (`ec2/ssh-edge-bootstrap-public`, `ec2/ssh-edge-bootstrap-private`; the `-public` one is a hard prerequisite for `terraform plan`/`apply` to succeed at all, since `data.vault_kv_secret_v2` fails to read a path that doesn't exist yet), then `terraform apply` itself.

**EIP cutover strategy:** When the new instance is ready, swap EIP via `terraform apply`. Route53 points to EIP so DNS is unchanged.

**Two real bugs found and fixed (2026-07-26 evening, via a dedicated on-server audit session against the live legacy instance, cross-checked and fixed from the control node):**

1. **`aws_edge` had zero group_vars, which would have broken every playbook run against it.** `inventory/group_vars/aws.yml` only applied to the `[aws]` inventory group by exact name; `[aws_edge]` matched nothing, so every Vault-sourced var (`ec2_users`, `apache_vhosts`, `mailbox_users`, `duo_*`, `vault_version`, etc.) would be undefined, and, the sharpest breakage, the `ansible_ssh_args` override needed for PAM-based Duo (`configure_duo-ssh`) to complete non-interactively would never apply, hanging or failing the Duo challenge on every run after the first. **Fix:** `inventory/aws_hosts`'s Terraform template now emits an `[aws_all:children]` group containing both `aws` and `aws_edge`; the vars file was renamed `group_vars/aws.yml` → `group_vars/aws_all.yml` so both groups inherit it. (The login user/key were *not* split per-group: `ansible_ssh_user` is already globally `kecsi`, and `ec2_ssh_key_file` already points at the `<key>2026` key, both already valid against the legacy box today, since the user manually renamed `admin`→`kecsi` there and added the new keypair ahead of time, so there is no divergence to encode.)
2. **EBS data-volume attach race at first boot, untested.** `aws_volume_attachment.data` is a separate resource created *after* `aws_instance.this`, i.e. issued as its own API call after the instance is already launched, but cloud-init's `fs_setup`/`mounts` modules run early in boot and don't wait or retry for a device to appear. If the volume attaches after that stage runs, the filesystem is silently never created; `nofail` lets boot continue anyway, leaving `/home`, `/var/www`, `/var/log` unmounted with no automatic recovery (cloud-init modules run once). **Fix:** `templates/cloud-init.yaml.tftpl` gained a `bootcmd:` stanza that polls for each device (`/dev/disk/by-id/nvme-...`) to exist before the `fs_setup`/`mounts` stage runs.

---

## What's Running (Audit Findings)

| Component | Details | Ansible role exists? |
|-----------|---------|----------------------|
| Apache2 | 7 vhosts across 2 domains; SSL, ModSecurity, ModEvasive, proxy | ✅ `setup_apache2` |
| Postfix | Multi-domain, PAM/system users, postscreen, DNSBL, DANE outbound TLS | ✅ `setup_email-server` |
| Dovecot | IMAPS + LMTP delivery, PAM auth, FTS Xapian | ✅ same role |
| Rspamd | DKIM sign/verify, SPF, greylisting, spam scoring (replaced OpenDKIM + Postgrey + SpamAssassin) | ✅ same role |
| OpenDMARC | DMARC validation milter | ✅ same role |
| Certbot | Let's Encrypt for all hosted domains; HTTP-01 webroot (<d>.com/.net), DNS-01 wildcard via acme-dns.io (<d1>.hu, <d2>.hu, found live 2026-07-26, see below) | ✅ `setup_apache2` |
| Unbound | Local DNSSEC-validating resolver (required for DANE) | ✅ `setup_unbound` |
| dnsmasq | Replaced by Unbound | ♻️ decommissioned |
| Docker | Installed, no containers running | ❌ None |
| Fail2Ban | Custom jail.local (SASL, Postfix, Dovecot jails, 24h bantime) | ✅ ec2-core covers install |
| Duo 2FA | Migrated 2026-07-04 from ForceCommand login_duo → PAM-based pam_duo.so, scoped to sshd only | ✅ `configure_duo-ssh` |
| AWS SSM agent | Added 2026-07-04 as an out-of-band rescue path independent of sshd | ✅ `setup_aws-ssm-agent` |
| SSH hardening | Codified 2026-07-04: MaxAuthTries 2, PermitRootLogin no, X11Forwarding no, no AgentForwarding, etc. (dropped the deprecated UsePrivilegeSeparation directive from the original lynis output) | ✅ `configure_ssh-hardening` |
| auditd | Security audit logging | ✅ ec2-core security-tools |
| Named system users | kecsi, orsi, peter, tamas + vault service account | ✅ `setup_users` |
| HashiCorp Vault | Migrated 2026-07-04 from old manual binary (v1.4.0, dead, bound to VPC IP) to APT package, initialized and unsealed, live at vault.<d2>.hu; old `200-<d2>.hu.conf` vhost's ProxyPass repointed from 172.30.2.246:8200 to 127.0.0.1:8200 (manual fix, that vhost file isn't Ansible-managed) | ✅ `setup_vault` |

### Decommissioned (not rebuilding)

| Component | Reason |
|-----------|--------|
| Nextcloud | Decommissioned, not worth carrying forward |
| Minecraft bedrock server | Already running on k8s cluster |
| MariaDB | Only needed by Nextcloud (decommissioned) |

---

## Data to Migrate

| Data | Size | Priority |
|------|------|----------|
| DKIM private keys (`/var/lib/rspamd/dkim/`) | tiny | 🔴 Critical: lose these = DKIM breaks |
| Website content `/var/www/` | ~1.15 GB | 🔴 Critical |
| Mailboxes `/home/*/Maildir/` | ~5.6 GB | 🔴 Critical |
| ~~Old Vault data (`/opt/hashicorp/vault-data/`, v1.4.0)~~ | ~172 MB | 🟢 Not migrated, had been dead/unreachable since ~2020, nothing depended on it; new Vault was freshly initialized instead (2026-07-04). Old data left in place on the legacy box, unused. |
| **Current live Vault data (`/opt/vault/data/`, initialized 2026-07-04)** | small | 🔴 **Critical, and easy to miss**: unlike the row above, this Vault is genuinely load-bearing now: since the 2026-07-12+ Vault/Ansible secrets migration, `inventory/group_vars/aws_all.yml` sources `ec2_users`/`apache_vhosts`/`apache_certs`/`mailbox_users`/`duo_*`/AWS creds/DKIM backups from it via AppRole lookups. Once the EIP swaps to the new instance, `vault.<d2>.hu` starts resolving there; if this data hasn't been migrated first, every Vault-sourced Ansible variable breaks (the plaintext `secrets.yml` fallback values are the only thing that would keep working). See `roles/setup_vault/README.md`'s "Data migration from old server" section, the same rsync mechanism as the (skipped) row above, but this time it must actually be done. Do this as part of cutover (stop Vault on the legacy box, rsync, start + unseal on the new box with the original 2026-07-04 unseal keys), not as a "someday" step. |
| Selected `/home/` user directories | ~8 GB | 🟡 Selective (active users only) |
| TLS certs `/etc/letsencrypt/` | small | 🟢 Can regenerate via certbot |

---

## Phased Plan

### Phase 1: `setup_users` role ✅ Done

Must run **before** `setup_email-server`: the mail stack references system users by name, and UIDs must exist on the new server before any data migration.

- UIDs pinned to match live server: rsync preserves numeric UIDs, so new server must match before Maildirs are copied
- kecsi (1000): sudo, adm, mail, docker groups; SSH key from secrets.yml
- orsi (1001), peter (1005), tamas (1006): mail-only users, password hash from secrets.yml
- vault (1008): service account, shell `/bin/false`
- UIDs 1002-1004 and 1007 skipped (deleted users, do not reuse)
- See `roles/setup_users/README.md` for full variable reference and `inventory/group_vars/aws_all.yml` for definitions

### Phase 2: `setup_email-server` role ✅ Done

Role fully implemented and covers:

- Postfix: multi-domain, PAM/system user delivery via LMTP to Dovecot, postscreen, DNSBL, DANE outbound TLS, virtual alias map, `/etc/aliases`
- Dovecot: IMAPS (port 993), LMTP delivery socket, PAM auth (system users), FTS Xapian
- Rspamd: DKIM signing/verification (2048-bit, selector `mail`), SPF, greylisting, spam scoring
- OpenDMARC: DMARC validation milter
- See `roles/setup_email-server/README.md` for full variable reference

### Phase 3: `setup_apache2` role ✅ Done

Role covers all 7 vhosts across both domains:

- <d1>.hu, hugo.<d1>.hu (static), vault.<d1>.hu (→ Vault 8200)
- <d2>.hu, zoltan.<d2>.hu (static), kepek.<d2>.hu (static + S3 proxy for /album/), vault.<d2>.hu (→ Vault 8200)
- Certbot: HTTP-01 webroot (<d>.com/.net), DNS-01 wildcard via acme-dns.io
  (<d1>.hu, <d2>.hu, found live 2026-07-26, see "What's Running" above); DNS-01
  Route53 also available but not currently used by any cert
- ModSecurity + ModEvasive; OCSP stapling; HSTS; ServerTokens Prod
- All vhosts defined in `inventory/group_vars/aws_all.yml`; see `roles/setup_apache2/README.md`
- **Note:** HTTP-01 cert issuance requires EIP to be swapped to the new instance first; the
  acme-dns wildcard certs don't have this restriction (DNS-01 validates independently of where
  the domain currently resolves), see Phase 6 step 2's cert-timing note below

### Phase 4: `setup_vault` role ✅ Done

- Installs Vault from HashiCorp APT repo (replaces old manual binary at `/opt/hashicorp/vault`)
- Bind address corrected to `127.0.0.1:8200` (was VPC IP `172.30.2.246:8200` on old server)
- systemd unit from package (old server had no unit, just a shell script)
- Version pinning via `vault_version` + `apt-mark hold`; leave empty for latest
- Apache vhosts already defined in `setup_apache2` (`vault.<d1>.hu`, `vault.<d2>.hu`)
- Unseal keys and root token are **not** managed by Ansible; they must be available for post-migration unseal
- See `roles/setup_vault/README.md` for data migration and unseal procedure

### Phase 5: New role: `setup_unbound` (est. 30min) ✅

Added to `ec2-core.yml`.

- Install unbound, configure as caching/forwarding resolver on 127.0.0.1:53
- Disable systemd-resolved, write static /etc/resolv.conf
- Forward to AWS VPC resolver (169.254.169.253) then Cloudflare; DNSSEC enabled
- Config validated with unbound-checkconf before apply

### Phase 6: New instance + data migration (est. 2-4h)

1. ✅ Terraform code done (2026-07-11): new EC2 instance alongside old one (separate resource, same SG) + 4-volume EBS layout. `terraform apply` not yet run, pending.
   - ⬜ OS-level mount/fstab step still needed before step 2 (formats + mounts the 4 volumes); see `docs/howtos/ec2-ebs-volumes.md`
2. Run playbooks in order (users before mail: UIDs must exist before data migration;
   web before mail: the mail role reuses the TLS cert Apache issues for `mail_cert_name`'s
   domain rather than issuing its own, see `setup_email-server/tasks/certbot.yml`):
   ```
   ec2-prerequisite → ec2-core (includes setup_users) → ec2-web → ec2-mail → ec2-vault
   ```
   **Cert-issuance timing within `ec2-web.yml` differs by method** (see `setup_apache2/README.md`'s
   "Certbot methods" table): `<d1>.hu`/`<d2>.hu` (`method: acme-dns`, wildcard) validate via
   a DNS TXT record delegated to acme-dns.io, independent of where the domain's A record currently
   points; these can issue successfully on the new instance **before** cutover. `<d>.com`/
   `<d>.net` (webroot/HTTP-01) validate by Let's Encrypt connecting to the domain over the
   public internet, which still resolves to the **old** instance until the EIP actually swaps; these
   will fail if issued before cutover. So a pre-cutover `ec2-web.yml` run (e.g. for initial
   verification) is expected to partially fail: 2 of 4 domains issue fine, the other 2 don't until
   after step 6 below. Not a bug; re-run `ec2-web.yml` again after the EIP swap to pick those up.
3. Migrate data (**after** setup_users has run so UIDs match):
   ```bash
   # DKIM keys
   rsync -av old-ec2:/var/lib/rspamd/dkim/ new-ec2:/var/lib/rspamd/dkim/

   # Website content
   rsync -av old-ec2:/var/www/ new-ec2:/var/www/

   # Mailboxes (system user Maildirs — ~5.6 GB total)
   # UIDs are pinned in setup_users so ownership is correct without chown
   rsync -av old-ec2:/home/kecsi/Maildir/ new-ec2:/home/kecsi/Maildir/
   rsync -av old-ec2:/home/orsi/Maildir/ new-ec2:/home/orsi/Maildir/
   rsync -av old-ec2:/home/peter/Maildir/ new-ec2:/home/peter/Maildir/
   rsync -av old-ec2:/home/tamas/Maildir/ new-ec2:/home/tamas/Maildir/

   # Current LIVE Vault data (initialized 2026-07-04, genuinely load-bearing —
   # NOT the old dead /opt/hashicorp/vault-data/ v1.4.0 path, which stays
   # unmigrated on the legacy box per the "Data to Migrate" table above).
   # Run after setup_vault so /opt/vault/data exists on the new box.
   # Stop Vault on the legacy box first for a consistent file-backend copy —
   # this is one of the very last things done before EIP cutover anyway.
   ssh old-ec2 sudo systemctl stop vault
   rsync -av --chown=vault:vault old-ec2:/opt/vault/data/ new-ec2:/opt/vault/data/
   # vault:vault is UID 1008 on both servers — ownership correct without chown,
   # --chown is just an explicit safety net
   ```
4. DNS smoke test: point one vhost to new instance, verify end-to-end
5. Start + unseal Vault on the new instance with the **original 2026-07-04 unseal keys**
   (not managed by Ansible, see `roles/setup_vault/README.md`), confirm
   `vault status`/`curl .../sys/health` healthy before proceeding
6. Terraform: swap EIP to new instance (`terraform apply` with updated `instance_id`)
7. Monitor 24h, then terminate old instance + delete the old rollback SG

---

## Roles Summary

| Role | Status | Playbook |
|------|--------|---------|
| `configure_ssh` | ✅ done | ec2-prerequisite + ec2-core |
| `configure_sudo` | ✅ done | ec2-prerequisite + ec2-core |
| `debian_upgrade` | ✅ done | ec2-core |
| `setup_legal_banner` | ✅ done | ec2-core |
| `setup_minimal` | ✅ done | ec2-core |
| `setup_network-tools` | ✅ done | ec2-core |
| `configure_ntp` | ✅ done | ec2-core |
| `setup_etckeeper` | ✅ done | ec2-core |
| `setup_security-tools` | ✅ done | ec2-core |
| `setup_users` | ✅ done | ec2-core |
| `setup_email-server` | ✅ done | ec2-mail |
| `setup_apache2` | ✅ done | ec2-web (new playbook) |
| `setup_unbound` | ✅ done | ec2-core |
| `setup_vault` | ✅ done | ec2-vault (new playbook) |
| `setup_aws-ssm-agent` | ✅ done, applied directly to the live legacy instance (2026-07-04 exception) | ec2-core |
| `configure_duo-ssh` | ✅ done, applied directly to the live legacy instance (2026-07-04 exception) | ec2-core |
| `configure_ssh-hardening` | ✅ done | ec2-core |

---

## Time Estimate

| Phase | Estimated time |
|-------|----------------|
| Phase 1: setup_users role | ✅ done |
| Phase 2: setup_email-server role | ✅ done |
| Phase 3: setup_apache2 role | ✅ done |
| Phase 4: setup_vault role | ✅ done |
| Phase 5: setup_unbound role | ✅ done |
| Phase 6: Migration + cutover | 2-4h |
| **Remaining** | **~2-4h** (migration + cutover only) |

Phases 1-5 were developed and tested without touching the live server, with the exception of the two 2026-07-04 hardening fixes noted in Context above (`setup_email-server`'s cron fix, `configure_duo-ssh` + `setup_aws-ssm-agent`), which were deliberately applied directly to the still-live legacy instance ahead of the rebuild.
