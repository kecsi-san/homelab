# configure_etc-hosts

Populates `/etc/hosts` on every node in the `kube` group with the static IP mappings of all cluster members, including the Kubernetes API load balancer VIP. This ensures that hostnames resolve correctly without depending on DNS infrastructure being available; which is especially important during cluster bootstrap.

## Why this role exists

During Kubespray cluster installation and early node setup, DNS may not yet be functional or reachable. Hardcoding cluster hostnames into `/etc/hosts` guarantees that:

- Nodes can reach each other by short hostname, FQDN, and `.localdomain` alias at all times
- The Kubernetes API endpoint (`api.k8s`) resolves to the kube-vip VIP before CoreDNS is running
- SSH, Ansible, and Kubernetes components do not fail due to DNS timeouts

## Requirements

- The `kube` group must be defined in the inventory with `ansible_host` set for every member
- `api.k8s` must be defined as a host in the inventory with `ansible_host` pointing to the kube-vip VIP
- The `domain_name` variable must be set (defined in `inventory/group_vars/all/all.yml`)

## Role variables

This role has no `defaults/` or `vars/` files. It consumes variables from the inventory directly.

| Variable | Source | Description |
|---|---|---|
| `domain_name` | `group_vars/all/all.yml` | Domain suffix for FQDN entries (e.g. `custom.local`) |
| `hostvars[item].ansible_host` | Inventory | IP address written into each `/etc/hosts` line |
| `groups.kube` | Inventory | List of all hosts in the `kube` group |

## What the role does

Iterates over every host in `groups.kube` plus the `api.k8s` VIP and writes a line into `/etc/hosts` in the following format:

```
<ip>  <hostname>.<domain_name>  <hostname>.localdomain  <hostname>
```

For the cluster defined in this repository the result is:

```
192.168.1.11   node01.custom.local   node01.localdomain   node01
192.168.1.12   node02.custom.local  node02.localdomain  node02
192.168.1.13   node03.custom.local  node03.localdomain  node03
192.168.1.14   node04.custom.local   node04.localdomain   node04
192.168.1.100  api.k8s.custom.local     api.k8s.localdomain     api.k8s
```

The `api.k8s` entry maps to the kube-vip VIP (`192.168.1.100`), which is the HA endpoint for `kube-apiserver`. The task uses `lineinfile` with a `regexp` guard so it is fully idempotent; re-running the role updates existing entries rather than duplicating them.

## Tags

| Tag | Description |
|---|---|
| `hosts` | Broad tag shared with other host-configuration tasks |
| `configure-etc-hosts` | Specific tag to target only this role |

Run only this role:

```bash
ansible-playbook playbooks/k8s-nodes.yml --tags configure-etc-hosts
```

## Example playbook

This role is included in `playbooks/k8s-nodes.yml` and runs early in the play order, before roles that depend on inter-node connectivity:

```yaml
- role: configure_etc-hosts
  become: true
  tags:
    - hosts
    - prerequisites
```

It should also be run as part of `playbooks/prerequik8s-nodes.yml` before the first Kubespray installation so that nodes can resolve each other during cluster bootstrap.

## Notes

- Entries are written to `/etc/hosts` on the **remote nodes**, not on the Ansible control node
- If a host's IP address changes, re-running the role will update the existing line in place (the `regexp` matches on the hostname at end-of-line)
- The role skips any item where `ansible_host` is not defined, preventing failures if inventory entries lack an IP
