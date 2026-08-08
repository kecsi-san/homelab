# setup_k3s

Installs a single-node k3s local development cluster.

- **Linux (WSL2 / Debian):** native k3s via the official installer script
- **macOS:** k3s via k3d (k3s in Docker); installed through Homebrew

Kubeconfig is written to `~/.kube/k3s.yaml` and appended to `KUBECONFIG` in `~/.bashrc`.

## What it does

| Step | Linux | macOS |
|------|-------|-------|
| Install | Official `get.k3s.io` script | `brew install k3d` |
| Start cluster | systemd service (auto-started by installer) | `k3d cluster create` |
| Kubeconfig | Copy `/etc/rancher/k3s/k3s.yaml` → `~/.kube/k3s.yaml` | `k3d kubeconfig get` → `~/.kube/k3s.yaml` |
| Shell integration | Append to `KUBECONFIG` in `~/.bashrc` | Same |

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `k3s_enabled` | `true` | Set to `false` to skip the role entirely |
| `k3s_cluster_name` | `dev` | Cluster name (used by k3d on macOS; cosmetic on Linux) |
| `k3s_kubeconfig_path` | `~/.kube/k3s.yaml` | Destination for the kubeconfig file |
| `k3s_disable_traefik` | `true` | Disable built-in Traefik ingress controller |
| `k3s_disable_servicelb` | `false` | Disable built-in ServiceLB (klipper) load balancer |
| `k3d_agents` | `0` | Number of k3d agent nodes (0 = server-only) |
| `k3d_api_port` | `6443` | Localhost port for the Kubernetes API server (macOS) |

## Usage

```yaml
- name: Setup k3s local development cluster
  ansible.builtin.import_role:
    name: setup_k3s
  when: k3s_enabled
  vars:
    k3s_enabled: true
    k3s_cluster_name: dev
    k3s_disable_traefik: true
    k3s_disable_servicelb: false
  tags:
    - k3s
```

## Notes

- **Idempotent on Linux:** skips install if `/usr/local/bin/k3s` already exists
- **Idempotent on macOS:** skips `k3d cluster create` if the named cluster already exists
- `KUBECONFIG` uses the colon-separated multi-file syntax; safe to combine with other cluster configs
- To uninstall, run `playbooks/reset-k3s.yml`
- macOS requires Docker Desktop (or OrbStack) to be running for k3d to work
- Traefik is disabled by default; use ingress-nginx or another controller for local testing
