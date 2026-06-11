# EC2 Edge Node Rebuild Plan

## Context

The EC2 edge node has been manually configured since 2016. Terraform now manages the infrastructure (security group, EIP, Route53). The goal is to build Ansible roles for everything running on the old instance, rebuild a fresh instance, migrate data, then swap the EIP — no DNS changes required.

**EIP cutover strategy:** When the new instance is ready, swap EIP via `terraform apply`. Route53 points to EIP so DNS is unchanged.

---

## What's Running (Audit Findings)

| Component | Details | Ansible role exists? |
|-----------|---------|----------------------|
| Apache2 | 8 vhosts across 2 domains; SSL, ModSecurity, ModEvasive, proxy | ❌ None |
| Postfix | Multi-domain, PAM/system users, postscreen, DNSBL, DANE outbound TLS | ✅ `setup_email-server` |
| Dovecot | IMAPS + LMTP delivery, PAM auth, FTS Xapian | ✅ same role |
| Rspamd | DKIM sign/verify, SPF, greylisting, spam scoring — replaced OpenDKIM + Postgrey + SpamAssassin | ✅ same role |
| OpenDMARC | DMARC validation milter | ✅ same role |
| Unbound | Local DNSSEC-validating resolver (required for DANE) | ✅ `setup_unbound` |
| dnsmasq | Replaced by Unbound | ♻️ decommissioned |
| Docker | Installed, no containers running | ❌ None |
| Certbot | Let's Encrypt for all hosted domains | ⚠️ referenced in mail role only |
| Fail2Ban | Custom jail.local (SASL, Postfix, Dovecot jails, 24h bantime) | ✅ ec2-core covers install |
| Duo 2FA | ForceCommand login_duo in sshd | ✅ ec2-prerequisite covers |
| SSH hardening | lynis_hardening.conf (MaxAuthTries 2, no X11, no AgentForwarding, etc.) | ⚠️ partially (banner + legal) |
| auditd | Security audit logging | ✅ ec2-core security-tools |
| Named system users | Multiple users with home directories and SSH access | ❌ None |
| HashiCorp Vault | Binary install, proxied via Apache | ❌ None |

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

### Phase 4 — New role: `setup_vault` (est. 2h)

New files: `roles/setup_vault/`, `playbooks/ec2-vault.yml`

- Download HashiCorp Vault binary from releases (version-pinned)
- Create vault system user, install to `/usr/local/bin`
- Systemd unit + config file (file storage backend, bind address)
- Apache2 vhost proxy entry (handled by setup_apache2 via `apache_vhosts` var)
- Note: unseal keys and root token are NOT stored in Ansible — manual step after deploy

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
| `setup_vault` | ❌ new | ec2-vault (new playbook) |

---

## Time Estimate

| Phase | Estimated time |
|-------|----------------|
| Phase 1 — setup_users role | ✅ done |
| Phase 2 — setup_email-server role | ✅ done |
| Phase 3 — setup_apache2 role | ✅ done |
| Phase 4 — Vault role | 2h |
| Phase 5 — setup_unbound role | ✅ done |
| Phase 6 — Migration + cutover | 2–4h |
| **Remaining** | **~2–4h** (Vault role + migration) |

Phases 1–5 can be developed and tested without touching the live server.
