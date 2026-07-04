# EC2 Edge Node Rebuild Plan

## Context

**The EC2 edge node currently running (`i-04dba0d34a28a972d`, `52.48.130.44`) is still the original instance manually configured since 2016** — it was brought under Terraform management via `terraform import` (security group, EIP, Route53), not replaced. Its EC2 `LaunchTime` shows a 2026-06 date, but that just reflects a reboot after an in-place Debian Bookworm → Trixie upgrade, not instance creation — don't mistake it for a fresh box.

**Plan history:** The original idea was to fully reverse-engineer this instance's configuration and apply the resulting Ansible + Terraform code *in place*, converging the live box itself into a fully codified, idempotent state without replacing hardware. This was investigated directly in a Claude Code session running on the instance itself. That investigation found enough accumulated manual drift from ~10 years of hands-on changes — legacy SSH keys from multiple eras, mail-stack components later found redundant and replaced (OpenDKIM + Postgrey + SpamAssassin → Rspamd), installed-but-unused software (Docker with no containers), decommissioned services left behind (Nextcloud, MariaDB), unserved static file leftovers — that safely reconciling it all in place via Ansible wasn't realistic. **That approach was abandoned.**

The current plan instead: build Ansible roles that capture the *desired* state (validated by reading the live box's config, not by running Ansible against it), provision a **new** EC2 instance, apply the full role set there fresh, migrate only the data that's actually valuable (DKIM keys, mailboxes, website content, Vault data — see below), swap the EIP, then decommission whatever remains on the old instance.

**Exception (2026-07-04):** Two narrow, self-contained fixes were applied directly to the still-live legacy instance ahead of the rebuild, rather than waiting for cutover: a `setup_email-server` cron bug fix (dovecot-fts `%` escaping), and a `configure_duo-ssh` + `setup_aws-ssm-agent` migration of SSH MFA from `ForceCommand login_duo` to PAM-based `pam_duo.so` (the old ForceCommand setup was making routine Ansible/ops work on this box impractically slow, one Duo push per SSH session). These are operational improvements to the box as it exists today — they are **not** progress toward Phase 6 below, and the new instance build should still apply these same roles fresh rather than assume anything carries over.

**Security fix (2026-07-04):** `inventory/group_vars/aws.yml` had `ec2_users`, `apache_certs`, `apache_vhosts`, `apache_server_admin`, and `vault_api_addr` committed in plaintext — real full names, UIDs, domain/vhost topology, and an internal Vault proxy target, directly violating this repo's own documented secrets.yml/vars.yml split. Moved into `secrets.yml` (gitignored). Also added `configure_ssh-hardening` (see Roles Summary below). Full Phase 6 automation (new instance + 4-volume EBS layout + provisioning/migration/cutover orchestration) remains a separate, not-yet-started follow-up.

**EIP cutover strategy:** When the new instance is ready, swap EIP via `terraform apply`. Route53 points to EIP so DNS is unchanged.

---

## What's Running (Audit Findings)

| Component | Details | Ansible role exists? |
|-----------|---------|----------------------|
| Apache2 | 7 vhosts across 2 domains; SSL, ModSecurity, ModEvasive, proxy | ✅ `setup_apache2` |
| Postfix | Multi-domain, PAM/system users, postscreen, DNSBL, DANE outbound TLS | ✅ `setup_email-server` |
| Dovecot | IMAPS + LMTP delivery, PAM auth, FTS Xapian | ✅ same role |
| Rspamd | DKIM sign/verify, SPF, greylisting, spam scoring — replaced OpenDKIM + Postgrey + SpamAssassin | ✅ same role |
| OpenDMARC | DMARC validation milter | ✅ same role |
| Certbot | Let's Encrypt for all hosted domains; HTTP-01 webroot + DNS-01 Route53 | ✅ `setup_apache2` |
| Unbound | Local DNSSEC-validating resolver (required for DANE) | ✅ `setup_unbound` |
| dnsmasq | Replaced by Unbound | ♻️ decommissioned |
| Docker | Installed, no containers running | ❌ None |
| Fail2Ban | Custom jail.local (SASL, Postfix, Dovecot jails, 24h bantime) | ✅ ec2-core covers install |
| Duo 2FA | Migrated 2026-07-04 from ForceCommand login_duo → PAM-based pam_duo.so, scoped to sshd only | ✅ `configure_duo-ssh` |
| AWS SSM agent | Added 2026-07-04 as an out-of-band rescue path independent of sshd | ✅ `setup_aws-ssm-agent` |
| SSH hardening | Codified 2026-07-04 — MaxAuthTries 2, PermitRootLogin no, X11Forwarding no, no AgentForwarding, etc. (dropped the deprecated UsePrivilegeSeparation directive from the original lynis output) | ✅ `configure_ssh-hardening` |
| auditd | Security audit logging | ✅ ec2-core security-tools |
| Named system users | kecsi, orsi, peter, tamas + vault service account | ✅ `setup_users` |
| HashiCorp Vault | Migrated 2026-07-04 from old manual binary (v1.4.0, dead, bound to VPC IP) to APT package, initialized and unsealed, live at vault.kecskemethy.hu — old `200-kecskemethy.hu.conf` vhost's ProxyPass repointed from 172.30.2.246:8200 to 127.0.0.1:8200 (manual fix, that vhost file isn't Ansible-managed) | ✅ `setup_vault` |

### Decommissioned (not rebuilding)

| Component | Reason |
|-----------|--------|
| Nextcloud | Decommissioned — not worth carrying forward |
| Minecraft bedrock server | Already running on k8s cluster |
| MariaDB | Only needed by Nextcloud (decommissioned) |

---

## Data to Migrate

| Data | Size | Priority |
|------|------|----------|
| DKIM private keys (`/var/lib/rspamd/dkim/`) | tiny | 🔴 Critical — lose these = DKIM breaks |
| Website content `/var/www/` | ~1.15 GB | 🔴 Critical |
| Mailboxes `/home/*/Maildir/` | ~5.6 GB | 🔴 Critical |
| ~~Vault data (`/opt/hashicorp/vault-data/`)~~ | ~172 MB | 🟢 Not migrated — old Vault (v1.4.0) had been dead/unreachable since ~2020, nothing depended on it; new Vault was freshly initialized instead (2026-07-04). Old data left in place, unused. |
| Selected `/home/` user directories | ~8 GB | 🟡 Selective (active users only) |
| TLS certs `/etc/letsencrypt/` | small | 🟢 Can regenerate via certbot |

---

## Phased Plan

### Phase 1 — `setup_users` role ✅ Done

Must run **before** `setup_email-server` — the mail stack references system users by name, and UIDs must exist on the new server before any data migration.

- UIDs pinned to match live server — rsync preserves numeric UIDs, so new server must match before Maildirs are copied
- kecsi (1000): sudo, adm, mail, docker groups; SSH key from secrets.yml
- orsi (1001), peter (1005), tamas (1006): mail-only users, password hash from secrets.yml
- vault (1008): service account, shell `/bin/false`
- UIDs 1002–1004 and 1007 skipped (deleted users — do not reuse)
- See `roles/setup_users/README.md` for full variable reference and `inventory/group_vars/aws.yml` for definitions

### Phase 2 — `setup_email-server` role ✅ Done

Role fully implemented and covers:

- Postfix: multi-domain, PAM/system user delivery via LMTP to Dovecot, postscreen, DNSBL, DANE outbound TLS, virtual alias map, `/etc/aliases`
- Dovecot: IMAPS (port 993), LMTP delivery socket, PAM auth (system users), FTS Xapian
- Rspamd: DKIM signing/verification (2048-bit, selector `mail`), SPF, greylisting, spam scoring
- OpenDMARC: DMARC validation milter
- See `roles/setup_email-server/README.md` for full variable reference

### Phase 3 — `setup_apache2` role ✅ Done

Role covers all 7 vhosts across both domains:

- linuxbox.hu, hugo.linuxbox.hu (static), vault.linuxbox.hu (→ Vault 8200)
- kecskemethy.hu, zoltan.kecskemethy.hu (static), kepek.kecskemethy.hu (static + S3 proxy for /album/), vault.kecskemethy.hu (→ Vault 8200)
- Certbot HTTP-01 (webroot) for both domains; DNS-01 Route53 available for Route53 zones
- ModSecurity + ModEvasive; OCSP stapling; HSTS; ServerTokens Prod
- All vhosts defined in `inventory/group_vars/aws.yml`; see `roles/setup_apache2/README.md`
- **Note:** cert issuance (HTTP-01) requires EIP to be swapped to the new instance first

### Phase 4 — `setup_vault` role ✅ Done

- Installs Vault from HashiCorp APT repo (replaces old manual binary at `/opt/hashicorp/vault`)
- Bind address corrected to `127.0.0.1:8200` (was VPC IP `172.30.2.246:8200` on old server)
- systemd unit from package (old server had no unit, just a shell script)
- Version pinning via `vault_version` + `apt-mark hold`; leave empty for latest
- Apache vhosts already defined in `setup_apache2` (`vault.linuxbox.hu`, `vault.kecskemethy.hu`)
- Unseal keys and root token are **not** managed by Ansible — must be available for post-migration unseal
- See `roles/setup_vault/README.md` for data migration and unseal procedure

### Phase 5 — New role: `setup_unbound` (est. 30min) ✅

Added to `ec2-core.yml`.

- Install unbound, configure as caching/forwarding resolver on 127.0.0.1:53
- Disable systemd-resolved, write static /etc/resolv.conf
- Forward to AWS VPC resolver (169.254.169.253) then Cloudflare; DNSSEC enabled
- Config validated with unbound-checkconf before apply

### Phase 6 — New instance + data migration (est. 2–4h)

1. Terraform: launch new EC2 instance alongside old one (separate resource, same SG)
2. Run playbooks in order (users before mail — UIDs must exist before data migration):
   ```
   ec2-prerequisite → ec2-core (includes setup_users) → ec2-mail → ec2-web → ec2-vault
   ```
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

   # Vault data (~172 MB — run after setup_vault so /opt/vault/data exists)
   # vault:vault (UID 1008) on both servers — ownership correct without chown
   # Vault will upgrade storage format on first start; unseal with original keys afterward
   rsync -av old-ec2:/opt/hashicorp/vault-data/ new-ec2:/opt/vault/data/
   ```
4. DNS smoke test: point one vhost to new instance, verify end-to-end
5. Terraform: swap EIP to new instance (`terraform apply` with updated `instance_id`)
6. Monitor 24h, then terminate old instance + delete the old rollback SG

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
| `setup_aws-ssm-agent` | ✅ done — applied directly to the live legacy instance (2026-07-04 exception) | ec2-core |
| `configure_duo-ssh` | ✅ done — applied directly to the live legacy instance (2026-07-04 exception) | ec2-core |
| `configure_ssh-hardening` | ✅ done | ec2-core |

---

## Time Estimate

| Phase | Estimated time |
|-------|----------------|
| Phase 1 — setup_users role | ✅ done |
| Phase 2 — setup_email-server role | ✅ done |
| Phase 3 — setup_apache2 role | ✅ done |
| Phase 4 — setup_vault role | ✅ done |
| Phase 5 — setup_unbound role | ✅ done |
| Phase 6 — Migration + cutover | 2–4h |
| **Remaining** | **~2–4h** (migration + cutover only) |

Phases 1–5 were developed and tested without touching the live server — with the exception of the two 2026-07-04 hardening fixes noted in Context above (`setup_email-server`'s cron fix, `configure_duo-ssh` + `setup_aws-ssm-agent`), which were deliberately applied directly to the still-live legacy instance ahead of the rebuild.
