# setup_firewall

A small, host-level iptables firewall in its own chain: trusted sources, optional SSH allow-list and country filter, static drops, and your own extra rules.

## What it does

- Installs `iptables` (Debian 13 uses the nft backend).
- Renders `/etc/homelab-firewall/rules.v4` and `rules.v6` for one chain (`HOMELAB-INPUT`), syntax-checks each file with `iptables-restore --test` before it replaces the live one, and applies them.
- `homelab-firewall.service` reloads the rules at boot, before `fail2ban.service`.
- Adds one jump `INPUT -> HOMELAB-INPUT`. Chains owned by other tools (fail2ban `f2b-*`, Docker) are never flushed or reordered, and the default INPUT policy stays ACCEPT. Your cloud security group remains the outer layer.

Rule order inside the chain: loopback, established/related, trusted sources (all ports), drop sources, SSH allow-list, country filter for SSH, then `firewall_extra_rules_*`.

fail2ban inserts its jumps at the top of `INPUT`, so a banned address is rejected even if it is trusted here. Put the same addresses in `fail2ban_ignoreip` (role `setup_fail2ban`).

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `firewall_enabled` | `false` | Playbooks run the role only when true |
| `firewall_ssh_port` | `22` | Port the SSH rules apply to |
| `firewall_trusted_sources` | `[]` | Addresses or CIDRs (IPv4 and IPv6) allowed on every port |
| `firewall_ssh_allow_sources` | `[]` | Addresses or CIDRs allowed on the SSH port only |
| `firewall_ssh_countries` | `[]` | Country codes allowed to reach SSH; others are dropped. Needs `setup_geoip` |
| `firewall_drop_sources` | `[]` | Addresses or CIDRs dropped everywhere |
| `firewall_extra_rules_v4` / `_v6` | `[]` | Raw rule fragments without `-A <chain>`, appended last |
| `firewall_ipv6` | `true` | Also manage ip6tables |
| `firewall_chain` | `HOMELAB-INPUT` | Chain name |
| `firewall_config_dir` | `/etc/homelab-firewall` | Where the rule files live |

Addresses must be literal IPs or CIDRs, not hostnames. IPv4 and IPv6 entries can share one list; the role splits them.

## Example

```yaml
firewall_enabled: true
firewall_trusted_sources:
  - 172.31.0.0/20        # private network of the same VPC
  - 198.51.100.10        # another server
firewall_ssh_allow_sources:
  - 203.0.113.5          # CI runner
firewall_ssh_countries: [HU, GB]
fail2ban_ignoreip: "{{ ['127.0.0.1/8', '::1'] + firewall_trusted_sources }}"
```

## Country filter

`firewall_ssh_countries` produces `-m geoip ! --source-country HU,GB --dport 22 -j DROP`, placed after the allow-lists, so trusted and allow-listed sources still get in from anywhere. Run `setup_geoip` first: the role stops with a clear message when a country file such as `/usr/share/xt_geoip/HU.iv4` is missing. `setup_geoip` re-inserts the geoip rule in place when the data refreshes (`iptables -R`), so the rule keeps its position.

## Safety

- Keep a second SSH session open the first time you apply on a remote host, and add your own address to `firewall_trusted_sources` or `firewall_ssh_allow_sources` before turning the country filter on.
- `iptables-restore --test` catches bad syntax and unknown options. It does not catch a jump to a chain that does not exist. The role only generates built-in targets; check any `firewall_extra_rules_*` you add.
- To switch it off quickly: `sudo iptables -D INPUT -j HOMELAB-INPUT` (and the `ip6tables` equivalent), then `sudo systemctl disable --now homelab-firewall.service`.

## Verify

```bash
sudo iptables -S INPUT
sudo iptables -S HOMELAB-INPUT
systemctl status homelab-firewall.service
```

Dry run before applying: `ansible-playbook -i <inventory> playbooks/ec2-core.yml --tags firewall --check --diff`.
