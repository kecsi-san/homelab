# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Does

Ansible automation for setting up and maintaining developer and DevOps environments. Uses a modular "LEGO" approach: each Ansible role is self-contained and independently runnable. Supports both local workstation setup and a distributed Kubernetes cluster (via Kubespray).

## Common Commands

```bash
# Install dependencies
pip install -r requirements.txt
ansible-galaxy install -r requirements.yml

# Local workstation — core system (brew, apt repos, minimal, network, python-uv)
ansible-playbook playbooks/local-core.yml

# Local workstation — security (sudo, duosecurity repo, fail2ban, rkhunter, lynis, trivy)
ansible-playbook playbooks/local-security.yml

# Local workstation — dev tooling (vscode, go, nodejs, rust)
ansible-playbook playbooks/local-dev.yml

# Local workstation — Cloud and DevOps tooling (terraform, iac-extra, aws, azure, gcp)
ansible-playbook playbooks/local-cloud.yml

# Local workstation — Kubernetes tooling (kubectl, helm, argocd, flux, kubeseal)
ansible-playbook playbooks/local-kube.yml

# Upgrade local workstation packages (apt, brew, uv)
ansible-playbook playbooks/upgrade-local.yml

# Run setup across kube group hosts
ansible-playbook playbooks/k8s-nodes.yml

# Run prerequisite SSH/sudo setup before k8s-nodes.yml (--ask-become-pass required here only — passwordless sudo not yet configured)
ansible-playbook --ask-become-pass playbooks/prerequisite.yml

# Pre-Kubernetes node preparation (etckeeper etc.)
ansible-playbook playbooks/pre-k8s.yml

# Install Kubernetes cluster
ansible-playbook -b playbooks/k8s.yml

# Reset/tear down Kubernetes cluster
ansible-playbook playbooks/reset-k8s.yml

# Post-Kubernetes setup (Longhorn storage, Traefik, etc.)
ansible-playbook playbooks/post-k8s.yml

# Post-k3s setup (Traefik, Sealed Secrets, ArgoCD)
ansible-playbook playbooks/post-k3s.yml

# OS upgrades on all kube group hosts
ansible-playbook playbooks/upgrade.yml

# Run only specific roles using tags
ansible-playbook --ask-become-pass -t ssh,sudo playbooks/prerequisite.yml
ansible-playbook -t minimal,brew playbooks/local-core.yml
ansible-playbook -t nodejs playbooks/local-dev.yml
ansible-playbook -t terraform,aws playbooks/local-cloud.yml
ansible-playbook -t kube playbooks/local-kube.yml

# Dry run (check mode)
ansible-playbook --check playbooks/local-core.yml

# Syntax check
ansible-playbook --syntax-check playbooks/local-core.yml
```

## Architecture

### Playbooks vs Roles

**Playbooks** (`playbooks/`) orchestrate roles for specific scenarios:
- `local-core.yml` — localhost only; core system setup (linuxbrew, apt repos, minimal packages, network, python-uv)
- `local-security.yml` — localhost only; security hardening (sudo, duosecurity repo, fail2ban, rkhunter, lynis, trivy)
- `local-dev.yml` — localhost only; developer tooling (vscode, go, nodejs, rust) — optional, run after local-core.yml
- `local-cloud.yml` — localhost only; Cloud tooling (terraform, iac-extra, aws, azure, gcp) — optional, run after local-core.yml
- `local-kube.yml` — localhost only; Kubernetes tooling (kubectl, helm, argocd, flux, kubeseal) — optional, run after local-core.yml
- `upgrade-local.yml` — localhost only; upgrades apt, brew, and uv packages
- `k8s-nodes.yml` — mirrors local-core.yml but targets `kube` group (remote hosts)
- `personalise.yml` — localhost only; taste-driven setup (fonts, shell prompt, wallpapers, profile image)
- `prerequisite.yml` — must run before `k8s-nodes.yml`; sets up SSH keys and passwordless sudo
- `k8s.yml` / `reset-k8s.yml` — delegate entirely to the Kubespray collection
- `pre-k8s.yml` — runs after `prerequisite.yml` and before `k8s.yml`; prepares nodes (etckeeper)
- `post-k8s.yml` — runs after Kubernetes cluster is up; installs cluster-level tools (Longhorn, kube-extra, Traefik, Sealed Secrets, Headlamp)
- `post-k3s.yml` — runs after k3s install; installs ArgoCD then bootstraps GitOps (ArgoCD manages Traefik, Sealed Secrets, Headlamp via kube-gitops/k3s/)
- `upgrade.yml` — OS package upgrades across all kube hosts

**Playbook naming convention:**
- Lowercase, hyphens only (no underscores), `.yml` extension
- Categories and patterns:
  - Environment setup → `<target>.yml` (e.g. `local-core.yml`, `k8s-nodes.yml`)
  - Kubernetes cluster ops → `[<phase>-]<tool>.yml` (e.g. `k8s.yml`, `pre-k8s.yml`, `post-k8s.yml`, `reset-k8s.yml`, `post-k3s.yml`)
  - Maintenance → `<operation>.yml` (e.g. `upgrade.yml`, `prerequisite.yml`)
  - One-off operations → `<specific-action>.yml` (e.g. `dist-upgrade.yml`)

**Roles** (`roles/`) are the building blocks. The LEGO principle means roles should have no dependencies on each other. Add new functionality by writing a new role and including it in the appropriate playbook.

### Roles Reference

#### Active / Implemented

| Role | Purpose |
|------|---------|
| `configure_etc-hosts` | Manages `/etc/hosts` with kube group IPs and domain names |
| `configure_fzf` | Adds fzf initialization to `~/.bashrc` (idempotent) |
| `configure_git` | Copies `~/.gitconfig` from static file |
| `configure_oh-my-posh` | Installs Pluto OMP theme; adds init block to `~/.bashrc` |
| `configure_ssh` | Deploys SSH authorized key for `ansible_ssh_user` |
| `configure_sudo` | Creates `/etc/sudoers.d/{user}` with NOPASSWD (visudo-validated) |
| `debian_upgrade` | `apt update && upgrade && autoremove --purge` |
| `disable_hibernation` | Creates `/etc/systemd/sleep.conf.d/nosuspend.conf`; masks sleep targets |
| `install_linuxbrew` | Installs Homebrew via `markosamuli.linuxbrew` (galaxy role, not vendored) |
| `install_nerd_fonts` | Installs Meslo LG + Fira Code Nerd Fonts via `homebrew_cask` |
| `setup_etckeeper` | Installs etckeeper; initialises git-backed `/etc` tracking |
| `setup_legal_banner` | Copies `banner.txt` to `/etc/issue*`; clears MOTD; reloads sshd |
| `setup_longhorn` | Installs iSCSI deps, longhornctl, and Longhorn via Helm |
| `setup_minimal` | Installs base + compression APT packages; optional brew base packages |
| `setup_network-tools` | Installs network diagnostic tools (APT on Linux, Homebrew on macOS) |
| `setup_python-uv` | Installs uv CLI tools (checkov, ansible, black, etc.) and Python library packages into `~/.venv/devops` |
| `setup_kube-extra` | Installs kubectl, helm, argocd, flux, kubeseal via Homebrew; bash completion system-wide (Linux: `/etc/bash_completion.d/`; macOS: `bash-completion@2` + Homebrew completion dir); `k` alias for kubectl |
| `setup_traefik` | Installs Traefik ingress controller via Helm; `delegate_to: localhost`; kubeconfig per cluster |
| `setup_sealed-secrets` | Installs Sealed Secrets controller via Helm; cluster-specific key pair for encrypting secrets safe to commit |
| `setup_headlamp` | Installs Headlamp Kubernetes dashboard via Helm; captures manual homelab install; flips service to ClusterIP |
| `setup_argocd` | Installs ArgoCD via Helm (argo-helm chart); sets insecure mode for Traefik TLS termination; displays initial admin password |
| `setup_argocd-apps` | Applies `kube-gitops/{k3s,k8s}/root.yaml` once; ArgoCD self-manages all child apps after bootstrap |
| `setup_go-dev-tools` | go, gopls, golangci-lint via Homebrew; optional: delve, goreleaser, ko, air |
| `setup_nodejs-dev-tools` | node, pnpm via Homebrew; optional brew + npm global packages |
| `setup_rust-dev-tools` | rustup + stable toolchain (rustc, cargo, rustfmt, clippy); optional cargo tools |
| `setup_vscode` | VS Code via apt (Linux) or Homebrew Cask (macOS); installs configured extensions |
| `upgrade_brew` | `brew update && upgrade && cleanup` — cross-platform (Linux/macOS brew paths via vars/os/) |
| `upgrade_python-uv` | `uv tool upgrade --all` + `uv pip install --upgrade` in devops venv |
| `upload_fav_bgimages` | Copies wallpapers to `/usr/share/backgrounds/`; generates GNOME background picker XML |
| `upload_profile_image` | Sets GNOME/GDM profile picture; image path set via `profile_image_src` variable (not stored in repo) |

#### Placeholder Roles (empty `tasks/main.yml`)

`setup_email-server`, `setup_email-tools`, `setup_mlops-tools`, `setup_aiops-tools`, `setup_mle-tools`

### Inventory Structure

`inventory/hosts` (gitignored — copy from `inventory/hosts.example`) defines:
- `local` group → `127.0.0.1` (localhost)
- `kube` group → physical servers (defined in `inventory/hosts`, gitignored)
- Kubernetes sub-groups under `k8s_cluster`: `kube_control_plane` (3 nodes), `kube_node` (4 nodes), `etcd` (3 nodes)
- `api.k8s` → `kube_vip_address` (Kubernetes API load balancer VIP via kube-vip, defined in `secrets.yml`)

Group variables in `inventory/group_vars/`:
- `all/all.yml` — Kubernetes cluster-wide settings (API server domain, load balancer)
- `all/secrets.yml` — **gitignored**; holds `domain_name`, `upstream_dns_servers`, `kube_vip_address`, `kube_vip_interface`. Copy from `secrets.yml.example`.
- `k8s_cluster/` — Network plugin (Calico) and addons config
- `kube.yml` — SSH user, Python interpreter, feature flags for the kube group
- `local.yml` — Same variables scoped to localhost

Key variables that control what gets installed: `linuxbrew: true/false`, `etckeeper: true/false`, `domain_name`, `admin_user`.

Variables `ansible_ssh_user` and `admin_user` are defined in `secrets.yml` (gitignored). `remote_user` in playbooks references `{{ ansible_ssh_user }}`.

Sensitive values (`admin_email`, `admin_full_name`, `git_user_signkey`, `git_user_email`) are Ansible-vaulted in `group_vars/local.yml`.

The `setup_kube-extra` role requires `kube_control_plane_host` to be set (short SSH hostname of a control plane node) — add it to `secrets.yml`.

### Role Conventions

Standard role layout:
```
roles/<role-name>/
├── tasks/main.yml
├── vars/main.yml          # Role-specific variables
├── vars/os/Debian.yml     # OS-specific overrides (Linux distro)
├── vars/os/Linux.yml      # Linux-specific variables
├── vars/os/Darwin.yml     # macOS-specific variables
├── files/                 # Static files
├── templates/             # Jinja2 templates
└── defaults/main.yml      # Overridable defaults
```

- Roles support both Linux (Debian/Ubuntu) and macOS (Darwin); use `when: ansible_system == 'Linux'` / `'Darwin'` guards where needed
- OS-specific variables live in `vars/os/{{ ansible_system }}.yml` (e.g. `Linux.yml`, `Darwin.yml`); distro-specific in `vars/os/{{ ansible_distribution }}.yml` (e.g. `Debian.yml`)
- Use `become: true` for system-level tasks; omit or use `become: false` for user-level tasks
- SSH user is defined via `admin_user` / `ansible_ssh_user` in `secrets.yml`; uses Ed25519 key (`~/.ssh/id_ed25519`)
- Prefer Linuxbrew for tools that update frequently; use APT (Linux) or Homebrew Cask (macOS) for system packages

### Tagging

Tags enable selective role execution without running the full playbook:
- `local-core.yml` tags: `brew`, `apt-repos`, `docker`, `apps`, `minimal`, `network`, `python`, `uv`
- `local-security.yml` tags: `sudo`, `apt-repos`, `security`, `checkov`
- `local-dev.yml` tags: `vscode`, `go`, `dev`, `nodejs`, `rust`, `gh`
- `local-cloud.yml` tags: `iac`, `terraform`, `iac-extra`, `cloud`, `aws`, `azure`, `gcp`
- `local-kube.yml` tags: `kube`, `kubernetes`
- `upgrade-local.yml` tags: `upgrade`, `apt`, `brew`, `uv`
- `k8s-nodes.yml` tags: `update`, `ssh`, `hosts`, `banner`, `fonts`, `omp`, `fzf`, `gitconfig`, `hibernation`

Always tag new roles consistently so users can run them individually.

### Kubernetes Setup

Two strategies, two different targets:

**Kubespray — bare-metal multi-node cluster (`kube` group)**
- Uses `kubernetes-sigs/kubespray` collection (release-2.29 branch, installed via `requirements.yml`)
- HA control plane with kube-vip at `api.k8s.<domain_name>:6443`, Calico CNI, 3-node etcd
- Kubespray group vars live in `inventory/group_vars/` alongside custom role vars — same inventory serves both
- Post-cluster setup (`post-k8s.yml`) installs Longhorn distributed block storage via `setup_longhorn`

**k3s — single-node local dev cluster (localhost)**
- Linux (WSL2): native k3s via official installer script (`get.k3s.io`)
- macOS: k3s via k3d (k3s in Docker) installed through Homebrew — requires Docker Desktop or OrbStack
- Kubeconfig written to `~/.kube/k3s.yaml` and appended to `KUBECONFIG` in `~/.bashrc`
- Managed by `setup_k3s` role; playbooks: `k3s.yml` (install), `reset-k3s.yml` (uninstall)
