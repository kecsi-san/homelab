# setup_geoip

Keeps the data behind an `xt_geoip` firewall rule (`-m geoip --source-country ...`) fresh on a Debian 13 host.

## What it does

- Installs `xtables-addons` (module and userspace), its DKMS source plus the headers of the running kernel, `geoipupdate`, and `python3-maxminddb`.
- Writes `/etc/GeoIP.conf` from the MaxMind account ID and license key (Vault, never the repo).
- Enables the stock `geoipupdate.timer` (Wednesday and Saturday).
- Adds `xt-geoip-build`, a small script that turns `GeoLite2-Country.mmdb` into the packed `<CC>.iv4` / `<CC>.iv6` files in `/usr/share/xt_geoip`, and a systemd drop-in so it runs after every successful `geoipupdate`.
- Re-inserts every iptables/ip6tables rule that uses `-m geoip` in place (`iptables -R`, rule position kept), because the kernel only loads the country ranges when a rule is added.

It does not create firewall rules. Those belong in the firewall role.

## Why a custom builder

Debian ships only a builder for MaxMind's CSV download (`xt_geoip_build_maxmind`), nothing runs it on a schedule, and `geoipupdate` only fetches `.mmdb` files. Left alone, the country files go stale (one host had files from 2023). `xt-geoip-build` reuses the download `geoipupdate` already does.

What the script does: reads `country.iso_code` (falls back to `registered_country`), merges adjacent ranges, skips the IPv6 aliases of IPv4 space, refuses to install if it sees fewer than 200 countries, builds in a temp directory, reads the files back and compares 5000 random addresses per family with the `.mmdb`, then replaces the files one by one. A run takes about 30 seconds and 230 MB of memory on a t3.small (`Nice=10`).

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `geoip_enabled` | `false` | Playbooks run the role only when true |
| `geoip_maxmind_account_id` | `""` | MaxMind account ID; set from Vault. The role fails when empty |
| `geoip_maxmind_license_key` | `""` | MaxMind license key; set from Vault. The role fails when empty |
| `geoip_enable_contrib` | `true` | Add the `contrib` component to `/etc/apt/sources.list.d/debian.sources` (`geoipupdate` is only there; official cloud images enable `main` only) |
| `geoip_edition_ids` | ASN, City, Country | Databases `geoipupdate` downloads; only Country is needed for the firewall |
| `geoip_apt_packages` | see defaults | Packages to install |
| `geoip_kernel_headers_package` | `linux-headers-<running kernel>` | DKMS needs these to build `xt_geoip` |
| `geoip_mmdb_dir` | `/var/lib/GeoIP` | Where `geoipupdate` writes |
| `geoip_xt_geoip_dir` | `/usr/share/xt_geoip` | Where the firewall module reads |

## Vault entry

Terraform (`terraform/vault/main.tf`, resource `vault_kv_secret_v2.maxmind_geoip`) creates the path `ec2/maxmind-geoip` with `CHANGE_ME` placeholders, so the path and the existing `ec2-ansible-read` policy are ready. The real values never go through Terraform: the resource is write-only with `disable_read`, so they stay out of state, and a later apply does not overwrite them. After `terraform apply` in `terraform/vault`, overwrite the placeholders once by hand with an `ec2-admin` login:

```bash
vault kv put ec2/maxmind-geoip account_id=<MaxMind account ID> license_key=<MaxMind license key>
vault kv get -field=account_id ec2/maxmind-geoip     # check it round-trips
```

`inventory/group_vars/aws_all.yml` reads it as `geoip_maxmind_account_id` and `geoip_maxmind_license_key` (Vault only, no `secrets.yml` fallback). The role refuses to run while a value is empty or still `CHANGE_ME`. Generate or rotate the key in the MaxMind account portal.

## Usage

```yaml
- name: Setup GeoIP firewall data
  ansible.builtin.import_role:
    name: setup_geoip
  become: true
  when: geoip_enabled | default(false)
  tags:
    - geoip
```

Dry run first, because the role overwrites `/etc/GeoIP.conf` and compares it against what the host has today:

```bash
ansible-playbook -i inventory/aws_hosts playbooks/ec2-core.yml --tags geoip --check --diff
```

## Verify

```bash
ls -la /usr/share/xt_geoip/HU.iv4                          # recent date
/usr/local/sbin/xt-geoip-build --dest /tmp/xt_geoip_test   # build only, touches nothing live
/usr/local/sbin/xt-geoip-build --dest /tmp/xt_geoip_test --lookup 203.0.113.10 198.51.100.7
systemctl list-timers geoipupdate.timer
journalctl -u xt-geoip-build.service --no-pager | tail
```

## Notes

- The reload step needs root and `CAP_NET_ADMIN`, so the unit runs as root with a modest sandbox (`ProtectSystem=strict`, writable `/usr/share/xt_geoip` and `/run`). If a future systemd or iptables version needs more, relax it there.
- `OnSuccess=` needs systemd 249 or newer (Debian 13 ships 257).
- The old special files `A1`, `A2` and `O1` (satellite and anonymous proxies) are not produced. Delete them if no rule uses them.
- Tested on a Debian 13 host with `python3-maxminddb` 2.x: country lookups were correct, the rule was replaced in place, and SSH was unaffected.
