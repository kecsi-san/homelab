# setup_email-server

Configures a full-featured personal/family email server with multi-domain support, DANE outbound TLS, DKIM signing, spam filtering, and full-text search.

## Stack

| Component | Role |
|---|---|
| **Postfix** | MTA; inbound SMTP (25, postscreen DNSBL), authenticated submission (587 STARTTLS + 465 implicit TLS), DANE outbound TLS |
| **Dovecot 2.4** | IMAP (IMAPS only, port 993), LMTP delivery, FTS via Xapian |
| **Rspamd** | DKIM sign/verify, SPF, greylisting, spam scoring |
| **OpenDMARC** | Inbound DMARC policy enforcement (port 25 only; skipped on 587/465, no point enforcing DMARC on our own outgoing mail); milter runs over TCP (`inet:127.0.0.1:8893`), not a unix socket, so it's reachable from Postfix's chroot jail |
| **Certbot** | Reuses the TLS cert `setup_apache2` issues for `mail_cert_name`'s domain (renewal timer + reload hook only; no issuance task here) |

## Auth and mailbox model

- **Auth**: PAM; users authenticate with their Linux system password (`/etc/shadow`)
- **Userdb**: `/etc/passwd`: home directory and uid/gid come from the system
- **Mailboxes**: Maildir format at `~/Maildir/` for each system user
- **Delivery**: Postfix → Dovecot LMTP → `~/Maildir/`
- System users must exist on the host before this role runs (created by another role or manually)

## Multi-domain routing

All served domains are listed in `mydestination`. A virtual address map (`/etc/postfix/virtual`) routes addresses to local system usernames. Define this via `mailbox_users` in inventory; each user's `domains` list controls which domains they receive mail on, and each domain entry can add extra alias local-parts (nicknames, role addresses) beyond the username itself:

```yaml
mailbox_users:
  - name: alice
    domains:
      - name: example.com
        aliases: [firstname, nickname]   # firstname@, nickname@, and alice@ all route to alice
      - name: example.net
        aliases: [firstname, nickname]
      - name: example.org
        include_self: false              # alice@example.org is NOT registered — only the aliases below are
        aliases: [firstname, sales, support]
```

Auth is PAM/system-password based (see `ec2_users` in `setup_users`), not a separate password here; `mailbox_users` only controls address-to-user routing.

## Accepting mail from internal LAN hosts with unresolvable HELO names

A trusted internal host (e.g. a home fileserver) delivering its own system mail (cron, fail2ban) to a local mailbox on this server will get rejected by `smtpd_helo_restrictions`' `reject_unknown_helo_hostname`, since a `.local`/LAN-only HELO/EHLO hostname never resolves in public DNS. Every retry also counts as a failed connection against `fail2ban`'s `postfix` jail, so it eventually bans the sending network's public IP too.

Set `postfix_helo_access_entries` to allowlist the exact HELO string:

```yaml
postfix_helo_access_entries:
  prolion.kinet.local: "OK"
```

This only bypasses the HELO hostname-resolvability checks for that literal string. Postscreen's DNSBL checks, rspamd's spam scoring, and the recipient/relay restrictions all still apply normally. It's deliberately not a `mynetworks`/IP-based exception (a home IP is usually dynamic and shared by the whole LAN) and not SASL authentication (that's for a host that needs to *relay* through this server to arbitrary external recipients, which is a different, higher-trust problem than delivering to one of this server's own local mailboxes).

## DKIM

Keys are generated at deploy time (2048-bit RSA) per domain using selector `{{ dkim_selector }}` (default: `mail`). Every run derives the public key from whatever's on disk and publishes it to Vault at `ec2/dkim-public/<domain>` (and backs up the private key to `ec2/dkim-private/<domain>`, disaster-recovery only, never read by Terraform). `terraform/aws` reads `ec2/dkim-public/<domain>` and publishes the actual Route53 TXT record; Terraform remains the only thing that ever calls the Route53 API. See `docs/howtos/vault-secrets-architecture.md`.

Key files: `/var/lib/rspamd/dkim/<domain>.<selector>.key`

To rotate keys: delete the `.key` file for that domain (or change `dkim_selector`), re-run this role, then run `terraform apply` in `terraform/aws` to publish the new value.

## Keys carried over from another server

To keep the existing DNS records, give the role the old keys and selectors instead of letting it generate new ones:

```yaml
dkim_domain_selectors:
  example.com: default
  example.org: selector1
dkim_private_keys:
  example.com: "{{ lookup('...', 'example.com') }}"   # PEM text, for example from Vault
  example.org: "..."
dkim_vault_sync: false   # the keys already live in Vault
```

Each key is written to `<rspamd_dkim_key_dir>/<domain>.<selector>.key` (mode 0400), and Rspamd signs each domain with its own selector. Domains without an entry in `dkim_domain_selectors` keep using `dkim_selector`. Rspamd reads the same PEM private keys that OpenDKIM uses, so no key conversion is needed and the signatures look the same to receivers.

## Supplied TLS certificate

By default Postfix and Dovecot expect a Let's Encrypt certificate under `certbot_cert_dir`. To use a certificate you bought, set:

```yaml
mail_tls_supplied: true
mail_tls_fullchain_pem: "..."   # leaf certificate followed by the chain
mail_tls_key_pem: "..."
mail_certbot_enabled: false
```

The role writes `fullchain.pem` (0644) and `privkey.pem` (0600) into `mail_tls_dir` (`/etc/ssl/mail`), points Postfix and Dovecot at them and reloads both when the files change. Renewal is manual: replace the values and rerun the role.

## Upstream filters and relays

If a filtering service delivers your inbound mail, list its addresses in `mail_trusted_relays`. The role then:

- lets those addresses skip postscreen's tests (`postscreen_access.cidr`),
- adds them to Rspamd's `local_addrs`, so Rspamd looks past them to the real sender when it checks SPF and blocklists,
- adds them to OpenDMARC's `IgnoreHosts`, because SPF for the relay's address would fail for every domain.

`mail_mynetworks` sets Postfix's `mynetworks` (networks that may relay without authentication). Left empty, the role does not set it and Postfix uses its default, the host's own subnet.

## Sieve

With `email_sieve_enabled: true` the role installs `dovecot-sieve`, runs Sieve scripts at delivery, and writes the scripts from `email_sieve_user_scripts` (`{username: "script text"}`) to each user's `~/.dovecot.sieve`. Every script is checked with `sievec` before it is written, so a syntax error stops the play. Folder names in `fileinto` are IMAP names with `.` as the separator, which matches Maildir++ directories (`fileinto "INBOX.work.reports"` delivers to `.INBOX.work.reports/`).

The Dovecot config also declares the special-use folders `Drafts`, `Junk`, `Trash` and `Sent`.

## Variables

| Variable | Default | Description |
|---|---|---|
| `mail_hostname` | `mail.<first domain>` | SMTP banner (`myhostname`) |
| `mail_cert_name` | `{{ mail_hostname }}` | TLS cert directory name under `certbot_cert_dir`: override to match the domain `setup_apache2`'s `apache_certs` actually issued a cert for (e.g. `l*.hu` covers `mail.l*.hu`) |
| `email_domains` | *(required)* | List of domains to serve |
| `dkim_selector` | `mail` | DKIM key selector |
| `rspamd_dkim_key_dir` | `/var/lib/rspamd/dkim` | DKIM private key directory |
| `postscreen_dnsbl_sites` | *(see defaults)* | DNSBL list with weights |
| `postscreen_dnsbl_threshold` | `3` | Score threshold to enforce block |
| `mailbox_users` | `[]` | Users and their domains (see above) |
| `mail_virtual_entries` | `{}` | Extra virtual map lines, verbatim: forwards to outside addresses, several targets, catch-alls, address to address |
| `mail_extra_destinations` | `[]` | Extra names accepted as local domains, for example `www.example.com` |
| `aliases_root` | `root` | System user who receives root's mail |
| `extra_aliases` | `{}` | Additional aliases, e.g. `{fail2ban: alice, wiki: alice}` |
| `postfix_helo_access_entries` | `{}` | HELO/EHLO hostnames to accept despite not resolving in public DNS, e.g. `{host.internal.example: "OK"}`; see below |
| `mail_tls_supplied` | `false` | Install a supplied certificate instead of expecting Let's Encrypt |
| `mail_tls_fullchain_pem`, `mail_tls_key_pem` | empty | PEM text of the supplied certificate chain and key |
| `mail_tls_dir` | `/etc/ssl/mail` | Where the supplied certificate is written |
| `mail_certbot_enabled` | `true` | Enable the certbot timer and reload hook |
| `dkim_domains` | `{{ email_domains }}` | Domains and host names that get a DKIM key (add sender names that are not mail domains) |
| `dkim_domain_selectors` | `{}` | Per-domain selectors when they differ from `dkim_selector` |
| `dkim_private_keys` | `{}` | PEM private keys per domain to install |
| `dkim_vault_sync` | `true` | Mirror keys into Vault and publish public keys for Terraform |
| `mail_mynetworks` | `[]` | Postfix `mynetworks`; empty keeps Postfix's default |
| `mail_trusted_relays` | `[]` | Upstream filters or relays that deliver inbound mail |
| `email_sieve_enabled` | `false` | Install Sieve and deploy the user scripts |
| `email_sieve_user_scripts` | `{}` | Sieve script text per user |

## Prerequisites

- A local DNSSEC-validating resolver on `127.0.0.1` (see `setup_unbound` role); required for DANE outbound TLS
- `setup_apache2` must have already run and issued a cert covering `mail_cert_name`'s domain (`ec2-web.yml` before `ec2-mail.yml`); this role does not issue its own cert
- System users already created on the host
- DNS: MX records pointing to `mail_hostname`; TLSA records for DANE. DKIM TXT records are published automatically via `terraform/aws` after Vault has a value (see DKIM section above); no manual DNS step

## Tags

| Tag | Scope |
|---|---|
| `postfix` | Postfix config and virtual map |
| `dovecot` | Dovecot config and FTS cron |
| `fts` | FTS config and cron only |
| `rspamd` | Rspamd config and DKIM keys |
| `dkim-dns` | Derive DKIM public key and back up key pair to Vault |
| `opendmarc` | OpenDMARC config |
| `tls` | Supplied certificate files |
| `sieve` | Sieve scripts |
| `certbot` | Certbot renewal timer + Postfix/Dovecot reload hook (no issuance; see Prerequisites) |
