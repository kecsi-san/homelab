# setup_unbound

Installs and configures Unbound as a full recursive, DNSSEC-validating
resolver on `127.0.0.1:53`. Deliberately **not** a forwarding resolver: a
forward-only resolver (the AWS VPC resolver, Cloudflare 1.1.1.1, etc.)
can't be trusted to set the DNSSEC `ad` (Authenticated Data) flag correctly,
which would silently break DANE TLS verification in Postfix
(`smtp_tls_security_level=dane`).

## What it does

- Installs `unbound` and `unbound-anchor` (separate package on Debian 13+,
  needed to initialize/update the root DNSSEC trust anchor)
- Disables and stops `systemd-resolved` (`ignore_errors: true`, not present
  on all Debian images), which otherwise owns port 53 via `127.0.0.53`
- Removes the `systemd-resolved`-managed `/etc/resolv.conf` symlink and
  writes a static one pointing at `127.0.0.1` (primary) with the AWS VPC
  resolver (`169.254.169.253`) as fallback
- Templates `/etc/unbound/unbound.conf`, validated with `unbound-checkconf`
  before it's ever applied (`validate:` on the template task)
- Enables and starts `unbound`

## Variables

| Variable | Default | Description |
|----------|---------|--------------|
| `unbound_prefetch` | `true` | Serve stale cached data while refreshing, reduces latency on cache expiry |
| `unbound_msg_cache_size` | `50m` | Message cache size (metadata) |
| `unbound_rrset_cache_size` | `100m` | RRset cache size (record data); kept at 2× `msg_cache_size`, the documented optimal ratio |
| `unbound_cache_min_ttl` | `3600` | Minimum cache TTL, seconds |
| `unbound_cache_max_ttl` | `86400` | Maximum cache TTL, seconds |
| `unbound_num_threads` | `1` | Worker threads; 1 is sufficient for a single-node mail server |

Hardening settings baked into the template (not overridable via variables):
`hide-identity`/`hide-version`, `harden-glue`/`harden-dnssec-stripped`/
`harden-below-nxdomain`/`harden-algo-downgrade`, `qname-minimisation`,
`use-caps-for-id` (0x20 encoding), and `private-address` rebind protection
for RFC1918/link-local ranges.

## Usage

```yaml
- name: Setup Unbound DNS resolver
  ansible.builtin.import_role:
    name: setup_unbound
  become: true
  tags:
    - unbound
    - dns
```

Wired into `ec2-core.yml` only: this is EC2 edge node infrastructure for
Postfix DANE, not used on the k8s/k3s clusters or local workstations.

## Notes

- `access-control: 127.0.0.0/8 allow`: loopback-only, no LAN or external
  clients can query this resolver.
- Postfix on the same host (`setup_email-server`) is the actual consumer of
  the DANE-dependent `ad` flag behavior; this role has no direct dependency
  on that role's tasks, but the two are functionally paired.
