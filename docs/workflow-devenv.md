# Workflow: Dev / DevOps Workstation Setup

Ansible automation for setting up a local developer or DevOps workstation.
Targets `localhost` and supports both **macOS** and **Debian/Ubuntu under WSL2** (Windows).

---

## Prerequisites

```bash
# Install Ansible dependencies
pip install -r requirements.txt
ansible-galaxy install -r requirements.yml

# Copy and fill in secrets
cp inventory/group_vars/all/secrets.yml.example inventory/group_vars/all/secrets.yml
```

Edit `secrets.yml` to set `admin_user`, `ansible_ssh_user`, `acme_email`, and MikroTik credentials.

---

## Playbook Sequence

Run in order. Each playbook is independently re-runnable — skip what you don't need.

### 1. Core system — `local-core.yml`

Foundation for everything else. Always run this first.

```bash
ansible-playbook playbooks/local-core.yml
```

| What | macOS | Linux (WSL2) |
|------|-------|-------------|
| Package manager | Homebrew | APT + Linuxbrew |
| Container runtime | Colima + Docker CLI | Docker CE via APT |
| Desktop apps | Firefox, Thunderbird, AppCleaner (Cask) | Firefox, Thunderbird (APT) |
| Base packages | fzf, gcc, git-delta, go-task, just, oh-my-posh, pre-commit, python@3.12, uv, yq | APT base + compression packages |
| Network tools | Homebrew | APT |
| Python tooling | uv: ansible, black, ruff, pytest, mkdocs, checkov, and more | same |

**Tags:** `brew`, `apt-repos`, `docker`, `apps`, `minimal`, `network`, `python`, `uv`

### 2. Security hardening — `local-security.yml`

```bash
ansible-playbook playbooks/local-security.yml
```

Installs: passwordless sudo (`configure_sudo`), Duo Security repo, fail2ban, rkhunter, lynis, trivy.

**Tags:** `sudo`, `apt-repos`, `security`, `checkov`

### 3. Developer tooling — `local-dev.yml` *(optional)*

```bash
ansible-playbook playbooks/local-dev.yml
```

Installs: VS Code, Go + gopls + golangci-lint, Node.js + pnpm, Rust + cargo toolchain, GitHub CLI.

**Tags:** `vscode`, `go`, `nodejs`, `rust`, `gh`, `dev`

### 4. Cloud tooling — `local-cloud.yml` *(optional)*

```bash
ansible-playbook playbooks/local-cloud.yml
```

Installs: Terraform, OpenTofu, Terragrunt, Trivy, AWS CLI, Azure CLI, Google Cloud SDK.

**Tags:** `iac`, `terraform`, `iac-extra`, `cloud`, `aws`, `azure`, `gcp`

### 5. Kubernetes tooling — `local-kube.yml` *(optional)*

```bash
ansible-playbook playbooks/local-kube.yml
```

Installs: kubectl, helm, argocd, flux, kubeseal. Bash completions wired up. `k` alias for kubectl.

**Tags:** `kube`, `kubernetes`

### Maintenance — `upgrade-local.yml`

```bash
ansible-playbook playbooks/upgrade-local.yml
```

Runs `brew upgrade`, `uv tool upgrade --all`, and on Linux `apt upgrade`.

**Tags:** `upgrade`, `apt`, `brew`, `uv`

### Personalisation — `personalise.yml`

```bash
ansible-playbook playbooks/personalise.yml
```

Installs Nerd Fonts, Oh My Posh shell prompt, sets user profile picture, uploads wallpapers (Linux).

---

## Running Specific Roles via Tags

```bash
# Single role
ansible-playbook -t brew playbooks/local-core.yml
ansible-playbook -t nodejs playbooks/local-dev.yml
ansible-playbook -t aws playbooks/local-cloud.yml
ansible-playbook -t kube playbooks/local-kube.yml

# Multiple roles
ansible-playbook -t minimal,network playbooks/local-core.yml
ansible-playbook -t go,rust playbooks/local-dev.yml
ansible-playbook -t terraform,aws playbooks/local-cloud.yml
```

## Dry Run

```bash
ansible-playbook --check playbooks/local-core.yml
ansible-playbook --syntax-check playbooks/local-core.yml
```

---

## macOS Notes

- **Homebrew** must be installed before running `local-core.yml` (install manually via `brew.sh` if not present)
- **Colima** is used as the Docker runtime instead of Docker Desktop — started automatically at login (`colima_autostart: true` in `group_vars/local.yml`)
- **Python interpreter** is pinned to `/usr/bin/python3` (Xcode CLT) in `group_vars/local.yml` to avoid compatibility issues with Homebrew Python versions
- **Bash completions** for docker, colima, and kube tools are wired into `~/.bash_profile` via `bash-completion@2`

## Linux (WSL2) Notes

- Linuxbrew is installed at `/home/linuxbrew/.linuxbrew/`
- Docker CE is installed via the official APT repo (not Docker Desktop)
- VS Code runs on Windows — the extension install step in `setup_vscode` may not work under WSL2 (disabled by default in `local-dev.yml`)
