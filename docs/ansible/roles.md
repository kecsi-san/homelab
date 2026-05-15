# Roles

Status legend: ✅ Done | 🔧 Implemented (not wired) | 🚧 Incomplete | 📋 Planned

---

## Naming Standard

Role names follow the pattern: **`<verb>_<subject>`** or **`<verb>_<subject>-<qualifier>`**

### Verbs

| Verb | When to use |
|------|-------------|
| `configure_` | Modifying config files, adjusting settings, or wiring shell initialisation |
| `setup_` | Installing packages/services or performing multi-step environment setup |
| `install_` | Installing a single tool or package manager via a package manager |
| `upload_` | Copying or deploying static files to remote hosts |
| `disable_` | Disabling or masking a system feature or service |
| `debian_` | OS-specific upgrade or migration tasks (Debian only) |
| `upgrade_` | Upgrading packages managed by a specific package manager (brew, uv, etc.) |
| `report_` | Notifications or announcements triggered at playbook completion |

### Subject

- Use **lowercase** only
- Use a **hyphen** (`-`) to separate multiple words within the subject: e.g. `setup_network-tools`, `setup_cloud-aws`
- Use an **underscore** (`_`) only as the separator between verb and subject

### Examples

```
configure_ssh          ✅ correct
setup_cloud-aws        ✅ correct
install_linuxbrew      ✅ correct
upload_fav_bgimages    ✅ correct
setupNetworkTools      ❌ wrong — no camelCase
setup_network_tools    ❌ wrong — underscores in subject
networktools_setup     ❌ wrong — subject before verb
```

---

## Directory and File Structure

Every role must have `tasks/main.yml` and `README.md`. Add the others as needed.

```
roles/<role-name>/
├── tasks/
│   └── main.yml           # Required — task definitions
├── defaults/
│   └── main.yml           # User-overridable variables (lowest precedence)
├── vars/
│   ├── main.yml           # Role-internal constants (not meant to be overridden)
│   └── os/
│       └── Debian.yml     # OS-specific variable overrides
├── files/                 # Static files deployed with ansible.builtin.copy
├── templates/             # Jinja2 templates deployed with ansible.builtin.template
├── handlers/
│   └── main.yml           # Handlers triggered by notify:
└── README.md              # Required — purpose, variables, usage, notes
```

Use `roles/role_template/` as a starting point when creating a new role.

---

## ✅ Done — implemented and wired into a playbook

| Role | Purpose | Playbook(s) |
|------|---------|-------------|
| `configure_etc-hosts` | Manages `/etc/hosts` with cluster node entries | k8s-nodes.yml |
| `configure_fzf` | Adds fzf shell integration to `~/.bashrc` | k8s-nodes.yml |
| `configure_git` | Deploys `~/.gitconfig` | k8s-nodes.yml |
| `configure_oh-my-posh` | Installs Pluto OMP theme and shell init | k8s-nodes.yml |
| `configure_ssh` | Deploys SSH authorized key | k8s-nodes.yml, prerequisite.yml |
| `configure_sudo` | Configures passwordless sudo for `admin_user` | k8s-nodes.yml, local-security.yml, prerequisite.yml |
| `debian_upgrade` | `apt update && upgrade && autoremove` | k8s-nodes.yml, upgrade.yml, upgrade-local.yml |
| `disable_hibernation` | Disables suspend/hibernate via systemd | k8s-nodes.yml |
| `install_linuxbrew` | Installs Homebrew via `markosamuli.linuxbrew` galaxy role (Linux only) | local-core.yml |
| `install_nerd_fonts` | Installs Meslo LG + Fira Code Nerd Fonts via Homebrew | k8s-nodes.yml |
| `setup_legal_banner` | Deploys SSH/login banner; clears MOTD | k8s-nodes.yml |
| `setup_etckeeper` | Git-backs `/etc` via etckeeper | pre-k8s.yml |
| `setup_apt_repos` | Adds Docker CE apt repo; installs docker-ce + compose plugin; adds user to docker group | local-core.yml |
| `setup_iac-extra` | Installs opentofu, terragrunt, terrascan, tfupdate via Homebrew | local-cloud.yml |
| `setup_iac-terraform` | Installs terraform, terraform-docs, tflint via Homebrew; trivy is a role default but omitted in local-cloud.yml (handled by `setup_security-tools`) | local-cloud.yml |
| `setup_cloud-aws` | awscli, aws-sam-cli, session-manager-plugin; optional: okta-aws-cli, eksctl, aws-vault | local-cloud.yml |
| `setup_cloud-azure` | azure-cli; optional: azd, bicep, azcopy, kubelogin | local-cloud.yml |
| `setup_cloud-gcp` | google-cloud-sdk (gcloud/gsutil/bq); optional: gke-gcloud-auth-plugin, cloud-sql-proxy | local-cloud.yml |
| `setup_kube-extra` | Installs kubectl, helm, argocd, flux, kubeseal via Homebrew; bash completions (Linux: `/etc/bash_completion.d/`; macOS: `bash-completion@2`); `k=kubectl` alias | local-kube.yml, post-k8s.yml |
| `setup_traefik` | Installs Traefik ingress controller via Helm (delegate_to: localhost); kubeconfig per cluster | post-k8s.yml |
| `setup_sealed-secrets` | Installs Sealed Secrets controller via Helm; cluster-specific key pair for git-safe encrypted secrets | post-k8s.yml |
| `setup_headlamp` | Installs Headlamp Kubernetes dashboard via Helm; ClusterIP service (Traefik routes via IngressRoute) | post-k8s.yml |
| `setup_argocd` | Installs ArgoCD via Helm (argo-helm chart); sets insecure mode for Traefik TLS termination; displays initial admin password | post-k3s.yml |
| `setup_argocd-apps` | Applies `kube-gitops/{k3s,k8s}/root.yaml` once via kubectl; ArgoCD self-manages all child apps after bootstrap | post-k3s.yml (post-k8s.yml after homelab rebuild) |
| `setup_longhorn` | Installs Longhorn distributed block storage via Helm | post-k8s.yml |
| `setup_minimal` | Installs base APT packages; optional Homebrew base packages | k8s-nodes.yml, local-core.yml |
| `setup_network-tools` | Installs network diagnostic tools (APT on Linux, Homebrew on macOS) | k8s-nodes.yml, local-core.yml |
| `setup_security-tools` | fail2ban + rkhunter (APT), lynis (Cisofy repo), trivy (Homebrew) | k8s-nodes.yml, local-security.yml |
| `setup_python-uv` | Installs uv CLI tools and Python library packages | local-core.yml |
| `setup_k3s` | Single-node k3s local dev cluster (Linux native / macOS via k3d) | k3s.yml |
| `setup_go-dev-tools` | go, gopls, golangci-lint via Homebrew; optional: delve, goreleaser, ko, air | local-dev.yml |
| `setup_nodejs-dev-tools` | node, pnpm via Homebrew; optional brew + npm global packages | local-dev.yml |
| `setup_rust-dev-tools` | rustup + stable toolchain (rustc, cargo, rustfmt, clippy); optional cargo tools | local-dev.yml |
| `upgrade_brew` | `brew update && upgrade && cleanup` — cross-platform (Linux/macOS brew paths via vars/os/) | upgrade.yml, upgrade-local.yml |
| `upgrade_python-uv` | `uv tool upgrade --all` + `uv pip install --upgrade` in devops venv | upgrade.yml, upgrade-local.yml |
| `upload_fav_bgimages` | Copies wallpapers to `/usr/share/backgrounds/`; generates GNOME XML descriptor (Linux only) | k8s-nodes.yml |
| `upload_profile_image` | Sets user profile picture — GNOME/GDM via AccountsService (Linux); macOS account picture via `dsimport`/`dscl`; source path set via `profile_image_src` | personalise.yml, k8s-nodes.yml |

---

## 🚧 Incomplete — needs work before use

| Role | Purpose | Notes |
|------|---------|-------|
| `setup_vscode` | Installs VS Code (apt on Linux, Homebrew Cask on macOS) and configures extensions | On WSL2 VS Code runs on Windows, not Linux — extension install step may not work as expected. Enabled is `false` by default in `local-dev.yml` until this is resolved. | 

---

## 📋 Planned — empty placeholders

| Role | Intended Purpose |
|------|-----------------|
| `setup_email-server` | Email server setup |
| `setup_email-tools` | Email client tools |
| `setup_mlops-tools` | MLOps tooling (MLflow, DVC, ZenML, Prefect, etc.) |
| `setup_aiops-tools` | AIOps tooling (OpenTelemetry, Prometheus, Grafana CLI, etc.) |
| `setup_mle-tools` | ML Engineering tooling (BentoML, Feast, vLLM, etc.) |
