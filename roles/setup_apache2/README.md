# setup_apache2

Installs and configures Apache2 with TLS, ModSecurity, ModEvasive, and all vhosts for the EC2 edge node.

## What it does

1. Installs Apache2, libapache2-mod-security2, modsecurity-crs, libapache2-mod-evasive, certbot
2. Enables modules: ssl, socache_shmcb, rewrite, proxy, proxy_http, headers, deflate, security2, evasive
3. Deploys a global security hardening config (ServerTokens Prod, OCSP stapling)
4. Issues TLS certificates via certbot (HTTP-01 webroot or DNS-01 Route53, per cert)
5. Deploys vhost configs from templates and enables them
6. Disables the default Apache site

## Certbot methods

| Method | When to use |
|--------|-------------|
| `webroot` (default) | Any domain — requires port 80 reachable and domain pointing at this server |
| `dns-route53` | Route53-hosted domains — works before DNS cutover |

The role deploys a global ACME challenge conf (`letsencrypt-webroot.conf`) that serves `/.well-known/acme-challenge/` from `/var/www/letsencrypt/` for all vhosts, so the webroot method works even after the default site is disabled.

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
| `extra_sans` | no | Additional SANs on the same cert |
| `method` | no | `webroot` (default) or `dns-route53` |

### `apache_vhosts` fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | yes | ServerName |
| `server_alias` | no | List of ServerAlias values |
| `server_admin` | no | Override admin email (falls back to `apache_server_admin`) |
| `ssl` | no | `true` (default) — port 80 redirects to HTTPS |
| `ssl_cert_domain` | yes (if ssl) | Certbot cert dir name — typically the apex domain |
| `docroot` | no | DocumentRoot for static sites (default `/var/www/<name>`) |
| `proxy_pass` | no | Full reverse proxy target URL (mutually exclusive with docroot) |
| `proxy_paths` | no | List of `{path, upstream}` for path-specific proxying alongside a docroot |
| `extra_config` | no | Raw Apache directives injected into the HTTPS vhost block |

## Playbook order

Run after:
1. `setup_users` — docroots under `/home/` are owned by system users
2. Docker installation (if any proxy_pass targets need Docker)
3. EIP swap to new instance (for HTTP-01 cert issuance)

Run before:
- `setup_vault` — vault vhosts are defined here; the vault service itself is set up by `setup_vault`

## Tags

| Tag | Scope |
|-----|-------|
| `apache2` | All tasks |
| `vhosts` | Vhost config and docroot creation only |
| `certbot` | Cert issuance and renewal config only |
