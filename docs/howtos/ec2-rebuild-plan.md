# EC2 Edge Node Rebuild Plan

## Context

The EC2 edge node has been manually configured since 2016. Terraform now manages the infrastructure (security group, EIP, Route53). The goal is to build Ansible roles for everything running on the old instance, rebuild a fresh instance, migrate data, then swap the EIP — no DNS changes required.

**EIP cutover strategy:** When the new instance is ready, swap EIP via `terraform apply`. Route53 points to EIP so DNS is unchanged.

---

## What's Running (Audit Findings)

| Component | Details | Ansible role exists? |
|-----------|---------|----------------------|
| Apache2 | 8 vhosts across 2 domains; SSL, ModSecurity, ModEvasive, proxy | ❌ None |
| Postfix | Multi-domain, virtual aliases, postscreen, DNSBL | ⚠️ `setup_email-server` (incomplete) |
| Dovecot | IMAPS | ⚠️ same role (incomplete) |
| OpenDKIM | Multiple domains | ⚠️ same role (incomplete) |
| OpenDMARC | DMARC validation milter | ❌ Not in role at all |
| Postgrey | Greylisting on :10023 | ❌ Not in role at all |
| SpamAssassin | spamd | ❌ Not in role at all |
| dnsmasq | Caching DNS resolver | ❌ None |
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
| DKIM private keys (`/etc/opendkim/keys/`) | tiny | 🔴 Critical — lose these = DKIM breaks |
| Website content `/var/www/` | ~1.15 GB | 🔴 Critical |
| Mailboxes `/var/mail/` | ~6 MB | 🔴 Critical |
| Selected `/home/` user directories | ~8 GB | 🟡 Selective (active users only) |
| TLS certs `/etc/letsencrypt/` | small | 🟢 Can regenerate via certbot |

---

## Phased Plan

### Phase 1 — Fix `setup_email-server` role (est. 2–3h)

The role structure (tasks, templates, vars) exists but is broken. Files to modify: `roles/setup_email-server/`.

- Add `handlers/main.yml` — Reload postfix / dovecot / opendkim
- Extend role to cover OpenDMARC, Postgrey, SpamAssassin (currently absent entirely)
- Add task to populate `/etc/dovecot/users` from `mailbox_users` variable (SHA512-CRYPT hashes)
- Template the Postfix custom rules: postscreen, DNSBL, SPF policy daemon, virtual aliases
- Test: `ansible-playbook -i inventory/aws_hosts playbooks/ec2-mail.yml --check`

### Phase 2 — New role: `setup_apache2` (est. 2–3h)

New files: `roles/setup_apache2/`, `playbooks/ec2-web.yml`

- Install Apache2 + modules: ssl, rewrite, proxy, proxy_http, headers, evasive, security2
- Template vhosts from variable-driven config: domain, docroot, aliases, proxy targets, SSL cert path
- Certbot integration: issue per-domain Let's Encrypt certs (DNS-01 via Route53 or HTTP-01)
- Capture the existing vhosts as role defaults (parameterised — no hardcoded domain names)
- Variable structure:
  ```yaml
  apache_vhosts:
    - name: www.example.com
      docroot: /var/www/example.com/public
      ssl: true
      certbot_domain: example.com
    - name: app.example.com
      proxy_pass: http://127.0.0.1:8200/
      ssl: true
  ```

### Phase 3 — New role: `setup_users` (est. 1h)

New files: `roles/setup_users/`, wired into `ec2-core.yml` or a new `ec2-users.yml`

- Create named system users with home dirs, SSH authorized_keys, optional sudo
- Variable-driven: `ec2_users` list with name, uid, groups, ssh_key, shell
- Decide which existing users need SSH access vs. mail-alias-only before running

### Phase 4 — New role: `setup_vault` (est. 2h)

New files: `roles/setup_vault/`, `playbooks/ec2-vault.yml`

- Download HashiCorp Vault binary from releases (version-pinned)
- Create vault system user, install to `/usr/local/bin`
- Systemd unit + config file (file storage backend, bind address)
- Apache2 vhost proxy entry (handled by setup_apache2 via `apache_vhosts` var)
- Note: unseal keys and root token are NOT stored in Ansible — manual step after deploy

### Phase 5 — New role: `setup_dnsmasq` (est. 30min)

Add to `ec2-core.yml` or standalone.

- Install dnsmasq, configure as caching resolver
- Disable systemd-resolved conflict if present

### Phase 6 — New instance + data migration (est. 2–4h)

1. Terraform: launch new EC2 instance alongside old one (separate resource, same SG)
2. Run playbooks against new instance: `ec2-prerequisite` → `ec2-core` → `ec2-web` → `ec2-mail` → `ec2-vault`
3. Migrate data:
   ```bash
   # DKIM keys (critical — do this first)
   rsync -av old-ec2:/etc/opendkim/keys/ new-ec2:/etc/opendkim/keys/

   # Website content
   rsync -av old-ec2:/var/www/ new-ec2:/var/www/

   # Mailboxes
   rsync -av old-ec2:/var/mail/ new-ec2:/var/mail/

   # User home dirs (selective)
   rsync -av old-ec2:/home/<user>/ new-ec2:/home/<user>/
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
| `setup_email-server` | ⚠️ fix needed | ec2-mail |
| `setup_apache2` | ❌ new | ec2-web (new playbook) |
| `setup_users` | ❌ new | ec2-core or ec2-users (new) |
| `setup_dnsmasq` | ❌ new | ec2-core |
| `setup_vault` | ❌ new | ec2-vault (new playbook) |

---

## Time Estimate

| Phase | Estimated time |
|-------|----------------|
| Phase 1 — Fix email role | 2–3h |
| Phase 2 — Apache2 role | 2–3h |
| Phase 3 — Users role | 1h |
| Phase 4 — Vault role | 2h |
| Phase 5 — dnsmasq role | 30min |
| Phase 6 — Migration + cutover | 2–4h |
| **Total** | **~10–14h across sessions** |

Phases 1–5 can be developed and tested without touching the live server.
