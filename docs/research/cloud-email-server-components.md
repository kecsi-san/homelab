---
title: "Self-Hosted Email Server: Component Analysis"
type: research
status: draft
scope: [general, ansible]
created: 2026-06-05
updated: 2026-06-05
tags: [email, postfix, dovecot, rspamd, dkim, dmarc, spf, tls, certbot, vps, aws, debian]
---

# Self-Hosted Email Server: Component Analysis

Analysis of email server component choices for a self-hosted deployment on a VPS.
Covers deployment approach, MTA, IMAP daemon, spam filtering, DKIM/DMARC, TLS automation,
and external DNS requirements. Intended to grow as components are evaluated and decided.

**Target platform:** AWS EC2 (Debian 13, bare-metal systemd; no containers).
**IaC approach:** Ansible role `setup_email-server`; native systemd integration.

---

## Deployment Approach: Container vs Bare-Metal

### Decision: bare-metal wins for this repo

Email service on a VPS touches many external concerns; DNS records, TLS certificates,
data persistence, spam reputation, fail2ban, and system-level port binding; that do not
fit cleanly inside a container boundary. Each of these either leaks out to the host or
requires a volume/network workaround that adds complexity without adding value.

The specific issues with containers here:
- **DNS**: A, MX, PTR, SPF, DKIM, DMARC records are external regardless of deployment method; no benefit from containerisation
- **TLS**: Let's Encrypt renewal must happen on the host (Certbot can't renew from inside a container without HTTP/DNS plumbing); Ansible handles this natively
- **Data store**: Maildir on host filesystem; volume mounts in containers add an indirection layer with no benefit on a single-purpose VPS
- **Systemd integration**: `systemctl reload postfix` for config changes; containers require a restart cycle instead
- **Fail2ban**: Needs to see host network stack for IP banning; container networking adds complexity
- **Ansible fit**: An Ansible role manages users, certs, DNS snippets, and config as idempotent code; docker-mailserver has no official Ansible integration

### docker-mailserver: reference analysis

**[docker-mailserver/docker-mailserver](https://github.com/docker-mailserver/docker-mailserver)**: 18.3k stars, 2k forks, ~3-4 releases/year. Ships Postfix + Dovecot + Rspamd + ClamAV +
OpenDKIM + OpenDMARC + Fail2ban in a single image. Config via 100+ env vars; file-based
storage (no SQL).

| Dimension | docker-mailserver (container) | Bare-metal + Ansible |
|-----------|------------------------------|----------------------|
| Setup complexity | Low; one `docker-compose up` | Higher; coordinate 5+ packages |
| Ansible integration | Weak; no official playbooks | Strong; full idempotency |
| Hot-reload | No; restart required for user/config changes | Yes; `systemctl reload postfix/dovecot` |
| TLS cert renewal | Host cron required; not self-contained | Ansible role handles end-to-end |
| Debugging | Harder; supervisord inside container | Native `journalctl`, direct process inspection |
| Customisation ceiling | Moderate (`user-patches.sh` overrides) | Unlimited |
| Reproducibility | High; image version pins stack | Medium; Debian package versions |
| Upgrades | `docker pull` + restart | `apt upgrade` per service |

**Verdict:** docker-mailserver is a valid fast-start option; bare-metal is the right
long-term fit for a repo already built around Ansible roles.

---

## Component Selection

### MTA (Mail Transfer Agent)

The MTA accepts and routes mail: inbound (port 25, SMTP) and outbound (submission, port 587).

| Option | Notes |
|--------|-------|
| **Postfix** | De facto standard; battle-tested; excellent Debian packaging; massive documentation and community; the right choice for almost every self-hosted setup |
| OpenSMTPD | Elegant config syntax (OpenBSD project); simpler than Postfix for basic setups; smaller ecosystem; less Ansible/automation tooling |
| Exim | Debian's historic default MTA; powerful but complex config; less commonly deployed in new homelab setups |
| Maddy | Modern Go-based unified MTA+IMAP; interesting but young and not yet production-proven at scale |
| Sendmail | Legacy; avoid |

**Selected: Postfix.** No credible reason to deviate on a standard self-hosted VPS deployment.

---

### IMAP / POP3 Daemon

Serves mailboxes to email clients (Thunderbird, Apple Mail, etc.) over IMAP-SSL (port 993).

| Option | Notes |
|--------|-------|
| **Dovecot** | De facto standard for self-hosted IMAP; excellent performance; Maildir and mbox; Sieve filtering; SASL auth provider for Postfix (SMTP AUTH); widely documented |
| Courier | Older; largely superseded by Dovecot |
| Cyrus IMAP | Enterprise-grade; complex; overkill for a single-VPS setup |
| Stalwart Mail | Modern Rust-based unified MTA+IMAP+JMAP server; built-in spam filtering; interesting but very new (~2023); limited production track record |

**Selected: Dovecot.** Also acts as SASL authentication provider for Postfix, making the
Postfix+Dovecot pair a natural unit that sovereign, docker-mailserver, and virtually every
other self-hosted mail setup uses.

---

### Spam Filtering

| Option | Notes |
|--------|-------|
| **Rspamd** | Modern; fast (C, async); built-in DKIM signing (eliminates OpenDKIM); Bayes filtering; web UI; actively developed; default in docker-mailserver; replaces SpamAssassin + OpenDKIM in one |
| SpamAssassin | Perl-based; older; slower; still widely used (sovereign uses it); well-understood rules |
| Amavis | Middleware layer that wires SpamAssassin and/or ClamAV into Postfix pipeline; not a filter itself; adds a process hop |
| Postscreen | Postfix built-in; connection-level filtering (RBL checks, greylisting) before message is accepted; complements, not replaces, a content filter |

**Selected: Rspamd.** Handles DKIM signing natively (see below), is significantly faster
than SpamAssassin, has a web UI for bayes training, and is actively developed.
Postscreen as an additional first-pass filter at the connection level.

---

### DKIM / DMARC Signing

DKIM signs outbound messages; DMARC policy is published in DNS and instructs recipients
how to handle failures.

| Option | Notes |
|--------|-------|
| **Rspamd built-in DKIM** | If Rspamd is already deployed, its DKIM module signs outbound mail; eliminates a separate daemon; key management via Rspamd config |
| OpenDKIM | Standalone milter daemon; works well; required if not using Rspamd; slightly more moving parts |
| OpenDMARC | DMARC policy enforcement milter; reports inbound DMARC failures; optional but recommended |

**Selected: Rspamd built-in DKIM** (since Rspamd is already in the stack) + OpenDMARC
for inbound DMARC enforcement and reporting.

---

### Antivirus (optional)

| Option | Notes |
|--------|-------|
| ClamAV | Open-source; integrates with Postfix via Amavis or directly via clamav-milter; auto-updates signatures; ~500-850 MB RAM cost |
| n/a | Skip entirely on a low-resource VPS; most dangerous attachments are caught by recipient-side AV; reputation-based spam filters catch most malware-carrying mail |

**Deferred.** ClamAV's RAM cost is significant on a small EC2 instance. Skip initially;
add if deliverability or security requirements change.

---

### Webmail (optional)

Webmail is not required; a standard IMAP client (Thunderbird, Apple Mail) works against
Dovecot directly. Only needed if browser-based access is a requirement.

| Option | Notes |
|--------|-------|
| Roundcube | Classic PHP webmail; feature-complete; CalDAV/CardDAV via plugins; widely deployed |
| Snappymail | Lightweight Roundcube fork; faster; fewer plugins |
| SOGo | Full groupware (CalDAV/CardDAV/ActiveSync); heavier; suits multi-user setups |

**Deferred.** Add Roundcube if browser access becomes necessary.

---

### TLS / Certificate Automation

Mail clients require a valid TLS certificate on port 993 (IMAP-SSL) and 587 (submission).

| Option | Notes |
|--------|-------|
| **Certbot + DNS-01 (Route53)** | Certificate issued and renewed without needing port 80/443; Route53 DNS plugin handles challenge automatically; systemd timer for renewal; works even if no web server runs on the VPS |
| Certbot + HTTP-01 | Simpler plugin; requires a web server (or `--standalone`) listening on port 80; fine if a web server is co-hosted |
| acme.sh | Lightweight alternative to Certbot; same DNS-01 + HTTP-01 options; shell-script based; good Ansible integration |

**Selected: Certbot + DNS-01 via Route53 plugin** (`python3-certbot-dns-route53`).
Renewal managed by a systemd timer on the host; Postfix and Dovecot reload on cert change
via a deploy hook. This approach works regardless of what else runs on the VPS and aligns
with Route53 already being used for DNS.

---

## External DNS Requirements

Every DNS record is a hard dependency; mail will silently fail or be rejected without them.

| Record | Type | Example value | Purpose |
|--------|------|---------------|---------|
| `mail.example.com` | A | `<EC2 EIP>` | Hostname for the mail server |
| `example.com` | MX | `10 mail.example.com` | Inbound mail routing |
| `<EC2 EIP>` | PTR | `mail.example.com` | Reverse DNS; required for deliverability; set in AWS console (contact support or use Elastic IP reverse DNS feature) |
| `example.com` | TXT | `v=spf1 mx -all` | SPF; authorises `mail.example.com` to send |
| `<selector>._domainkey.example.com` | TXT | (Rspamd-generated key) | DKIM public key |
| `_dmarc.example.com` | TXT | `v=DMARC1; p=quarantine; rua=mailto:...` | DMARC policy |
| `_mta-sts.example.com` | TXT | `v=STSv1; id=<timestamp>` | MTA-STS policy (optional but recommended) |
| `_smtp._tls.example.com` | TXT | `v=TLSRPTv1; rua=mailto:...` | TLSRPT reporting (optional) |

PTR record is the most commonly missed; AWS requires a support request or uses the
"Reverse DNS" field on the Elastic IP in the EC2 console.

---

## Recommended Stack Summary

| Layer | Choice | Rationale |
|-------|--------|-----------|
| MTA | Postfix | Industry standard; best Ansible/documentation ecosystem |
| IMAP | Dovecot | SASL auth for Postfix; Sieve; de facto standard |
| Spam filter | Rspamd + Postscreen | Modern, fast; web UI; handles DKIM signing |
| DKIM signing | Rspamd built-in | Eliminates OpenDKIM process; key managed in Rspamd config |
| DMARC enforcement | OpenDMARC | Inbound policy enforcement + aggregate reports |
| Antivirus | Deferred | RAM cost outweighs benefit on small instance |
| Webmail | Deferred | IMAP clients sufficient; add Roundcube if needed |
| TLS certs | Certbot + DNS-01 (Route53) | Port-agnostic renewal; aligns with Route53 DNS management |
| Deployment | Bare-metal systemd + Ansible | Full IaC; hot-reload; no container overhead |

---

## Reference Projects

- **[sovereign/sovereign](https://github.com/sovereign/sovereign)**: 10.5k stars; Ansible playbooks for full self-hosted VPS mail: Postfix + Dovecot + SpamAssassin + OpenDKIM + Roundcube. Closest match to the bare-metal Ansible approach, though uses SpamAssassin over Rspamd.
- **[docker-mailserver/docker-mailserver](https://github.com/docker-mailserver/docker-mailserver)**: 18.3k stars; containerised reference for how the components wire together; useful for config cross-reference even if not used directly.
- **[Rspamd documentation](https://rspamd.com/doc/)**: canonical reference for Rspamd + DKIM setup.
- **[Postfix documentation](https://www.postfix.org/documentation.html)**: canonical Postfix config reference.
