# setup_kube-extra

Installs Kubernetes CLI tooling, sets up system-wide bash completions, and adds a `k=kubectl` alias.

## What it does

1. Installs `kubectl` via Homebrew
2. Installs `helm` via Homebrew, plus the `helm-diff` plugin and `helm-docs`
3. Installs `argocd` CLI via Homebrew
4. Installs `flux` CLI via Homebrew (`fluxcd/tap`)
5. Installs `kubeseal` CLI via Homebrew
6. Installs `krew` (kubectl plugin manager) via Homebrew
7. Generates and installs bash completions system-wide for kubectl/helm/argocd/flux/kubeseal (`/etc/bash_completion.d/`)
8. Creates `/etc/profile.d/kubectl-alias.sh` with `k=kubectl` alias and tab completion for `k`

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `kubectl_bin` | `/home/linuxbrew/.linuxbrew/bin/kubectl` | Path to kubectl binary |
| `helm_bin` | `/home/linuxbrew/.linuxbrew/bin/helm` | Path to helm binary |
| `argocd_bin` | `/home/linuxbrew/.linuxbrew/bin/argocd` | Path to argocd binary |
| `flux_bin` | `/home/linuxbrew/.linuxbrew/bin/flux` | Path to flux binary |

## Usage

```yaml
- name: Setup kube extra tooling
  ansible.builtin.import_role:
    name: setup_kube-extra
  tags:
    - kube
    - kubernetes
```

## Notes

- Requires Homebrew (`install_linuxbrew` role)
- Completions are system-wide (`/etc/bash_completion.d/`) — requires `become: true` internally
- The `k` alias completion relies on `__start_kubectl` being loaded from the kubectl completion script
- Open a new shell after first run for completions and alias to take effect
