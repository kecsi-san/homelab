# setup_apache2

Installs and configures Apache2 with TLS, ModSecurity, ModEvasive, and all vhosts for the EC2 edge node.

## What it does

1. Installs Apache2, libapache2-mod-security2, modsecurity-crs, libapache2-mod-evasive, certbot, python3-requests (acme-dns hook dependency)
2. Enables modules: ssl, socache_shmcb, rewrite, proxy, proxy_http, headers, deflate, security2, evasive
3. Deploys a global security hardening config (ServerTokens Prod, OCSP stapling)
4. Issues TLS certificates via certbot (HTTP-01 webroot, DNS-01 Route53, or wildcard via acme-dns, per cert)
5. Deploys vhost configs from templates and enables them
6. Disables the default Apache site

## Certbot methods

| Method | When to use |
|--------|-------------|
| `webroot` (default) | Any domain; requires port 80 reachable and domain pointing at this server |
| `dns-route53` | Route53-hosted domains; works before DNS cutover |
| `acme-dns` | Wildcard cert (`*.domain`) for domains with no DNS API access (e.g. .hu registrars); avoids maintaining an explicit SAN list by hand every time a new subdomain is added |

The role deploys a global ACME challenge conf (`letsencrypt-webroot.conf`) that serves `/.well-known/acme-challenge/` from `/var/www/letsencrypt/` for all vhosts, so the webroot method works even after the default site is disabled.

### acme-dns wildcard certs: one-time setup

`acme-dns` uses the free [acme-dns.io](https://auth.acme-dns.io) delegation service plus the standard [joohoi/acme-dns-certbot-hook](https://github.com/joohoi/acme-dns-certbot-hook) script (`files/acme-dns-auth.py`, vendored as-is, no secrets embedded; only `/etc/letsencrypt/acmedns.json`, which the role deploys from Vault, is sensitive). One-time steps, done outside Ansible:

1. First issuance for a new domain: run the hook manually once (or let the role's first `certbot certonly` run trigger registration); it prints a `_acme-challenge.<domain> CNAME <random>.auth.acme-dns.io.` record to add to the domain's real DNS zone. Add that CNAME via the registrar's web UI (this delegates just that one TXT record to acme-dns.io; nothing else about the zone changes).
2. Save the resulting `/etc/letsencrypt/acmedns.json` content into Vault: `vault kv put ec2/acme-dns acmedns_json=@/etc/letsencrypt/acmedns.json`: this is what `acme_dns_json` (`inventory/group_vars/aws_all.yml`) reads on every subsequent run/host.
3. For a **rebuild** (new instance, same domains): skip step 1 entirely; the CNAME delegation already exists in the real DNS zone from the original setup, so just make sure the *same* `acmedns.json` content (same account credentials) is in Vault before running this role. Registering a new acme-dns account instead of reusing the existing one would require redoing the CNAME delegation, since the new account gets a different random subdomain.

**Timing:** certbot HTTP-01 requires the domain to resolve to this server. Issue certs after swapping the EIP to the new instance.

## Vhost types

| Type | How to configure |
|------|-----------------|
| Static site | Set `docroot` |
| Full reverse proxy | Set `proxy_pass` (no `docroot`) |
| Static site + path proxy | Set `docroot` + `proxy_paths` list |
| Raw directives | Use `extra_config` string injected into HTTPS vhost |

## Variables

Defined in `inventory/group_vars/aws_all.yml`. Sensitive values (`acme_email`) in `secrets.yml`.

| Variable | Default | Description |
|----------|---------|-------------|
| `apache_certs` | `[]` | Certs to issue (see below) |
| `apache_vhosts` | `[]` | Vhost definitions (see below) |
| `apache_server_admin` | `webmaster@localhost` | Default ServerAdmin for all vhosts |
| `certbot_email` | `{{ acme_email }}` | Let's Encrypt registration email |
| `certbot_cert_dir` | `/etc/letsencrypt/live` | Certbot cert directory |

### `apache_certs` fields

| Field | Required | Description |
|-------|----------|-------------|
| `domain` | yes | Primary domain (also the cert directory name) |
| `extra_sans` | no | Additional SANs on the same cert; ignored for `method: acme-dns` (the wildcard already covers every subdomain) |
| `method` | no | `webroot` (default), `dns-route53`, or `acme-dns` (wildcard) |

### `apache_vhosts` fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | yes | ServerName |
| `server_alias` | no | List of ServerAlias values |
| `server_admin` | no | Override admin email (falls back to `apache_server_admin`) |
| `ssl` | no | `true` (default); port 80 redirects to HTTPS |
| `ssl_cert_domain` | yes (if ssl) | Certbot cert dir name; typically the apex domain |
| `docroot` | no | DocumentRoot for static sites (default `/var/www/<name>`) |
| `proxy_pass` | no | Full reverse proxy target URL (mutually exclusive with docroot) |
| `proxy_paths` | no | List of `{path, upstream}` for path-specific proxying alongside a docroot |
| `extra_config` | no | Raw Apache directives injected into the HTTPS vhost block |

## Playbook order

Run after:
1. `setup_users`: docroots under `/home/` are owned by system users
2. Docker installation (if any proxy_pass targets need Docker)
3. EIP swap to new instance (for HTTP-01 cert issuance)

Run before:
- `setup_vault`: vault vhosts are defined here; the vault service itself is set up by `setup_vault`

## Tags

| Tag | Scope |
|-----|-------|
| `apache2` | All tasks |
| `vhosts` | Vhost config and docroot creation only |
| `certbot` | Cert issuance and renewal config only |
