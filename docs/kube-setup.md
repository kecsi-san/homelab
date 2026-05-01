# Kubernetes Setup

Two Kubernetes strategies are supported — each targets a different environment:

| | Kubespray | k3s |
|-|-----------|-----|
| **Target** | Bare-metal remote hosts (`kube` group) | localhost only |
| **Use case** | Production-grade HA cluster | Local development |
| **Nodes** | Multi-node (3 control plane + workers) | Single-node |
| **macOS support** | No | Yes (via k3d) |
| **Playbook sequence** | `prerequisite` → `k8s-nodes` → `pre-k8s` → `k8s` → `post-k8s` | `k3s` → `post-k3s` |

## Inventory Structure

```
inventory/
├── hosts                          # gitignored — copy from hosts.example
├── hosts.example                  # template
└── group_vars/
    ├── all/
    │   ├── all.yml                # Kubespray cluster-wide settings
    │   ├── secrets.yml            # gitignored — copy from secrets.yml.example
    │   └── secrets.yml.example    # template: domain, DNS, SSH user, kube-vip
    ├── kube.yml                   # Feature flags for remote hosts
    ├── local.yml                  # Feature flags for localhost (vaulted values)
    └── k8s_cluster/               # Kubespray network and addons config
```

Key variables in `secrets.yml`:

| Variable | Description |
|----------|-------------|
| `domain_name` | Base domain (e.g. `home.lab`) |
| `admin_user` / `ansible_ssh_user` | SSH login user |
| `upstream_dns_servers` | DNS resolvers for cluster nodes |
| `kube_vip_address` | VIP for the Kubernetes API load balancer |
| `kube_vip_interface` | Network interface for kube-vip |
| `kube_control_plane_host` | Short SSH hostname of a control plane node (used by `setup_kube-extra`) |

Kubespray group vars live in `inventory/group_vars/` alongside custom role vars — the same inventory serves both Kubespray and custom roles.

## Bare-Metal Cluster (Kubespray)

Uses [kubernetes-sigs/kubespray](https://github.com/kubernetes-sigs/kubespray) (release-2.29), installed via `requirements.yml`.

**Cluster configuration:**
- HA control plane with kube-vip at `api.k8s.<domain_name>:6443`
- Calico CNI
- 3-node etcd cluster

### Deployment Sequence

```bash
# 1. SSH hardening + passwordless sudo
#    (--ask-become-pass required here only — sudo not yet configured)
ansible-playbook --ask-become-pass playbooks/prerequisite.yml

# 2. Full node setup (shell tools, banners, fonts, network tools)
ansible-playbook playbooks/k8s-nodes.yml

# 3. Pre-cluster node preparation (etckeeper)
ansible-playbook playbooks/pre-k8s.yml

# 4. Install Kubernetes cluster via Kubespray
ansible-playbook -b playbooks/k8s.yml

# 5. Post-cluster: Longhorn storage, Traefik, Sealed Secrets, Headlamp
ansible-playbook playbooks/post-k8s.yml
```

### Maintenance

```bash
# OS package upgrades on all kube nodes
ansible-playbook playbooks/upgrade.yml

# Tear down cluster (destructive)
ansible-playbook playbooks/reset-k8s.yml
```

### Running Specific Roles via Tags

```bash
ansible-playbook --ask-become-pass -t ssh,sudo playbooks/prerequisite.yml
ansible-playbook -t hosts,banner,fonts playbooks/k8s-nodes.yml
ansible-playbook -t update playbooks/k8s-nodes.yml
```

**k8s-nodes.yml tags:** `update`, `ssh`, `hosts`, `banner`, `fonts`, `omp`, `fzf`, `gitconfig`, `hibernation`

## Local Dev Cluster (k3s)

Single-node cluster on localhost — no remote inventory or SSH required.

| Platform | Implementation |
|----------|---------------|
| Linux (WSL2) | Native k3s via official installer (`get.k3s.io`) |
| macOS | k3s via k3d (k3s in Docker) via Homebrew — requires Colima, Docker Desktop, or OrbStack |

Kubeconfig is written to `~/.kube/k3s.yaml` and appended to `KUBECONFIG` in `~/.bashrc`.

```bash
# Install
ansible-playbook playbooks/k3s.yml

# Post-install: ArgoCD bootstrap — ArgoCD then manages Traefik, Sealed Secrets, Headlamp
ansible-playbook playbooks/post-k3s.yml

# Uninstall
ansible-playbook playbooks/reset-k3s.yml
```
