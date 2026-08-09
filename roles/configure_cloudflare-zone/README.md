# configure_cloudflare-zone

Manages Cloudflare zone settings and DNS `A` records via the Cloudflare REST
API. Two independent concerns in one role: DNS records that Ansible owns
outright (`community.general.cloudflare_dns`), and a zone-level setting
(Encrypted Client Hello) managed by hand-rolled `uri` calls since no
`community.general` module covers it.

## What it does

- Loops `cloudflare_dns_records` through `community.general.cloudflare_dns`,
  `state: present`, one record per item (see `tasks/dns.yml`)
- Reads the zone's current ECH setting via the Cloudflare API, and `PATCH`es
  it only when it differs from `cloudflare_ech_enabled` (idempotent, avoids
  an unconditional write on every run)

## Variables

| Variable | Default | Description |
|----------|---------|--------------|
| `cloudflare_api_token` | _(secrets.yml)_ | API token, needs `Zone:DNS:Edit` scope |
| `cloudflare_settings_token` | `{{ cloudflare_api_token }}` | Token used for zone settings calls, needs `Zone:Settings:Edit` scope; falls back to `cloudflare_api_token` if not set separately in `secrets.yml` |
| `homelab_wan_ip` | _(secrets.yml)_ | Public WAN IP, used for direct (non-proxied) DNS records |
| `cloudflare_dns_records` | see `defaults/main.yml` | List of `{zone, record, type, value, ttl, proxied}`; `proxied: false` required for UDP services (e.g. the Minecraft `A` record) since Cloudflare's proxy only handles HTTP(S)/TCP |
| `cloudflare_ech_enabled` | `false` | Zone-level Encrypted Client Hello setting |

## Usage

```yaml
- name: Configure Cloudflare zone settings
  ansible.builtin.import_role:
    name: configure_cloudflare-zone
  tags: [cloudflare-zone, cloudflare-dns, cloudflare-ech]
```

Run standalone:

```bash
ansible-playbook playbooks/configure-cloudflare.yml
```

## Notes

- `cloudflare_zone_id` (used by the ECH tasks) isn't defined in this role;
  it must come from `inventory/group_vars/all/secrets.yml`.
- This role only ever creates/updates DNS records, never deletes them: same
  convention as `configure_mikrotik-router`. Stale records need manual
  cleanup in the Cloudflare dashboard.
- `external-dns` (the ArgoCD-managed Helm app) is a separate, independent
  Cloudflare DNS writer for the Cloudflare Tunnel path. It manages its own
  CNAME records per `IngressRoute` and isn't related to this role's static
  `A` records.
