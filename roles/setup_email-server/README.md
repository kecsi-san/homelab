# setup_email-server

Configures a full-featured personal/family email server with multi-domain support, DANE outbound TLS, DKIM signing, spam filtering, and full-text search.

## Stack

| Component | Role |
|---|---|
| **Postfix** | MTA — inbound/outbound SMTP, postscreen DNSBL, DANE outbound TLS |
| **Dovecot 2.4** | IMAP (IMAPS only, port 993), LMTP delivery, FTS via Xapian |
| **Rspamd** | DKIM sign/verify, SPF, greylisting, spam scoring |
| **OpenDMARC** | Inbound DMARC policy enforcement |
| **Certbot** | Let's Encrypt TLS cert via Route53 DNS-01 challenge |

## Auth and mailbox model

- **Auth**: PAM — users authenticate with their Linux system password (`/etc/shadow`)
- **Userdb**: `/etc/passwd` — home directory and uid/gid come from the system
- **Mailboxes**: Maildir format at `~/Maildir/` for each system user
- **Delivery**: Postfix → Dovecot LMTP → `~/Maildir/`
- System users must exist on the host before this role runs (created by another role or manually)

## Multi-domain routing

All served domains are listed in `mydestination`. A virtual address map (`/etc/postfix/virtual`) routes `user@any-domain` to the local system username. Define this via `mailbox_users` in inventory:

```yaml
mailbox_users:
  - name: kecsi
    domains:
      - kecskemethy.hu
      - kecskemethy.com
      - kecskemethy.net
      - kecskemethy.org
      - linuxbox.hu
```

## DKIM

Keys are generated at deploy time (2048-bit RSA) per domain using selector `{{ dkim_selector }}` (default: `mail`). Every run derives the public key from whatever's on disk and publishes it to Vault at `ec2/dkim-public/<domain>` (and backs up the private key to `ec2/dkim-private/<domain>`, disaster-recovery only, never read by Terraform). `terraform/aws` reads `ec2/dkim-public/<domain>` and publishes the actual Route53 TXT record — Terraform remains the only thing that ever calls the Route53 API. See `docs/howtos/vault-secrets-architecture.md`.

Key files: `/var/lib/rspamd/dkim/<domain>.<selector>.key`

To rotate keys: delete the `.key` file for that domain (or change `dkim_selector`), re-run this role, then run `terraform apply` in `terraform/aws` to publish the new value.

## Variables

| Variable | Default | Description |
|---|---|---|
| `mail_hostname` | `mail.<first domain>` | SMTP banner, TLS cert CN, Dovecot SSL |
| `email_domains` | *(required)* | List of domains to serve |
| `dkim_selector` | `mail` | DKIM key selector |
| `rspamd_dkim_key_dir` | `/var/lib/rspamd/dkim` | DKIM private key directory |
| `certbot_email` | `{{ acme_email }}` | Let's Encrypt account email |
| `postscreen_dnsbl_sites` | *(see defaults)* | DNSBL list with weights |
| `postscreen_dnsbl_threshold` | `3` | Score threshold to enforce block |
| `mailbox_users` | `[]` | Users and their domains (see above) |
| `aliases_root` | `root` | System user who receives root's mail |
| `extra_aliases` | `{}` | Additional aliases, e.g. `{fail2ban: kecsi, wiki: kecsi}` |

## Prerequisites

- A local DNSSEC-validating resolver on `127.0.0.1` (see `setup_unbound` role) — required for DANE outbound TLS
- AWS credentials available to certbot for Route53 DNS-01 validation
- System users already created on the host
- DNS: MX records pointing to `mail_hostname`; TLSA records for DANE. DKIM TXT records are published automatically via `terraform/aws` after Vault has a value (see DKIM section above) — no manual DNS step

## Tags

| Tag | Scope |
|---|---|
| `postfix` | Postfix config and virtual map |
| `dovecot` | Dovecot config and FTS cron |
| `fts` | FTS config and cron only |
| `rspamd` | Rspamd config and DKIM keys |
| `dkim-dns` | Derive DKIM public key and back up key pair to Vault |
| `opendmarc` | OpenDMARC config |
| `certbot` | TLS certificate issuance |
