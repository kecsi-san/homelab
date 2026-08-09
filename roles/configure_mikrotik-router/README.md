# configure_mikrotik-router

Upserts static DNS records (`A` and `AAAA`) and NAT (`dst-nat`) rules on the
MikroTik router via the `community.routeros` API modules. Must run before
`playbooks/k8s.yml` so `kubeadm` can resolve the API VIP hostname
(`api.k8s.<domain>`) during cluster init.

## What it does

- `tasks/nat.yml`: for each entry in `mikrotik_nat_rules`, finds an existing
  rule by its `comment` field (`api_find_and_modify`) and updates it, or
  adds it if no match (`api`)
- Same find-or-add pattern for `mikrotik_dns_records` (`A`, matched by
  `name`+`type`) and `mikrotik_dns6_records` (`AAAA`)

The find-then-add two-step is needed because `community.routeros.api` has no
native upsert; `api_find_and_modify` reports zero matches when the record is
new, and that result feeds the follow-up "add missing" task via `loop_control`.

## Variables

| Variable | Default | Description |
|----------|---------|--------------|
| `mikrotik_host` / `mikrotik_user` / `mikrotik_password` | _(secrets.yml)_ | Router API connection |
| `mikrotik_dns_ttl` | `"5m"` | TTL applied to every managed `A`/`AAAA` record |
| `mikrotik_dns_records` | see `defaults/main.yml` | List of `{name, address, match_subdomain}`; covers the k8s API VIP, k8s/k3s Traefik wildcards, NFS backup host, and Minecraft |
| `mikrotik_nat_rules` | see `defaults/main.yml` | List of `{comment, in_interface, protocol, dst_port, to_address, to_port}`; matched idempotently by `comment` |
| `mikrotik_dns6_records` | see `defaults/main.yml` | `AAAA` overrides pointing wildcard domains to `::1`, so Happy Eyeballs prefers the `A` record over Cloudflare's public IPv6 proxy address on LAN |

## Usage

```yaml
- name: Configure MikroTik router (DNS records + NAT rules)
  ansible.builtin.import_role:
    name: configure_mikrotik-router
  tags: [mikrotik, mikrotik-dns, mikrotik-nat]
```

Run standalone:

```bash
ansible-playbook playbooks/configure-router.yml
```

## Notes

- **Never deletes records**, only adds/updates. Stale entries need manual
  removal via Winbox or SSH.
- RouterOS processes static DNS entries top-to-bottom; more specific
  `match_subdomain` entries (e.g. `k3s.<domain>`) must be ordered before
  broader wildcards (`<domain>`) in `mikrotik_dns_records`, or the wildcard
  wins the match first.
- Re-run after any Traefik LB IP change, domain config change, or port
  forward addition, not just once at cluster bring-up.
