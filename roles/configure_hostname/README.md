# configure_hostname

Sets the host name and FQDN, writes the host's own entry (and optional peers) into `/etc/hosts`, and can set `/etc/mailname`. It is for servers outside the Kubernetes `kube` group, where `configure_etc-hosts` does not apply.

## What it does

- Checks that a short name and a domain are set. Neither has a default, so a missing variable fails the play.
- Writes one marked block into `/etc/hosts`: `<self ip> <fqdn> <short>` plus any `hostname_extra_hosts`. Other lines in the file are left alone.
- Sets the host name through systemd. `/etc/hosts` is written first, so `sudo` can still resolve the new name.
- On hosts with `/etc/cloud/cloud.cfg.d` (EC2 images), adds a file that sets `preserve_hostname: true` so cloud-init leaves the name alone on later boots.
- Optionally writes `/etc/mailname`.

Run it before installing Postfix, because the Debian package writes `/etc/mailname` from the host name at install time.

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `hostname_enabled` | `false` | Playbooks run the role only when true |
| `hostname_short` | none | Short name, for example `server1` (required) |
| `hostname_domain` | none | Domain, for example `example.com` (required unless `hostname_fqdn` is set) |
| `hostname_fqdn` | `<short>.<domain>` | Full name |
| `hostname_self_ip` | `127.0.1.1` | Address of the host's own entry |
| `hostname_extra_hosts` | `[]` | List of `{ip, names}` entries added to `/etc/hosts` |
| `hostname_mailname` | empty | Content of `/etc/mailname`; empty leaves the file alone |
| `hostname_preserve_cloud_init` | `true` | Keep cloud-init from resetting the name |

## Usage

```yaml
- name: Set the host name
  ansible.builtin.import_role:
    name: configure_hostname
  become: true
  when: hostname_enabled | default(false)
  tags:
    - hostname
```

Host or group variables:

```yaml
hostname_enabled: true
hostname_short: server1
hostname_domain: example.com
hostname_extra_hosts:
  - ip: 192.0.2.10
    names: [peer.example.com, peer]
hostname_mailname: mail.example.com
```

## Notes

- Debian convention: the static host name is the short name, and the FQDN comes from `/etc/hosts` (`hostname -f`).
- The marked block is replaced as a whole on each run. Remove a peer by deleting it from `hostname_extra_hosts`.
- The role does not change DNS, reverse DNS or the Postfix `myhostname`. DNS and the mail role handle those.
