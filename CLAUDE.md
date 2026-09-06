# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Does

Ansible automation for setting up and maintaining developer and DevOps environments. Uses a modular "LEGO" approach: each Ansible role is self-contained and independently runnable. Supports both local workstation setup and a distributed Kubernetes cluster (via Kubespray).

## Working Conventions

- **Solo repo, no branches/PRs**: this repo has a single maintainer. Commit and push directly to `main` — don't create feature branches or open PRs unless explicitly asked to.
- **Conventional Commits**: subject lines follow the `type(scope): description` format (`feat`, `fix`, `docs`, `chore`, etc. — see git log for examples). No JIRA/ticket reference; `git-changelog` parses these for `CHANGELOG.md`.
- **GitOps app inventory can drift from this file**: the app tables below are hand-maintained and can lag behind reality. When auditing or reconciling the app stack, verify against `kube-gitops/{k8s,k3s}/apps/*.yaml` directly (`spec.source`/`spec.sources` for Helm chart+repo vs raw manifest path, `spec.syncPolicy.automated` to confirm it's actually live) rather than trusting this file alone.
- **Git and secrets stay on the control node**: all commits/pushes happen from this repo on the control node, never from a Claude Code session running directly on a remote host (EC2, a kube node). Bring findings/fixes from an on-server investigation back here to commit. Sensitive values stay Vault/ansible-vault protected, never plaintext on a remote box even temporarily.
- **Onboard new host groups from the control node**: investigate a new host (OS, existing manual config, installed tooling) via read-only SSH from here, dry-run with `--check --diff`, then apply — don't spin up a Claude Code session on the target server for role rollout. Reserve an on-server session for genuinely bespoke app-level debugging that will never become a reusable role.
- **`TODO.md`** (repo root) is the single cross-session task tracker — check it before starting new work. Completed items move to the one `## Done` section at the bottom, never left inline in a topical section or duplicated elsewhere.
- **Release roughly every 3 months** (`git tag` + `gh release create`) even with work still in progress — releases are checkpoints, not "done" states. `CHANGELOG.md` regenerates automatically via `git-changelog`. Give `--title` a descriptive suffix (e.g. `vX.Y.Z — <description>`); it renders blank if it exactly equals the tag name. `git fetch`/rebase first if anything else merged earlier in the session — tagging the wrong commit doesn't move the tag, but pushing `main` after can get rejected.
- **Don't proactively poll CI** (`gh run watch`) after pushing — failures get reported separately; only check if asked, or a change is unusually risky and needs confirming green before a dependent next step.
- **For live-cluster maintenance with real blast radius** (data migration, scaling, GitOps sync state changes): state the plan before executing, and prefer blocking calls (`kubectl wait`) over background-then-poll-then-kill patterns. For the EC2 edge node specifically — a single production instance with no staging copy — confirm before *any* connection attempt, including read-only/`--check`.
- **Prefer a narrow, live, read-only check over trusting static review alone** when auditing config-drift-prone systems (EC2, any hand-configured host) — static analysis can only compare what's written against what's written elsewhere, not what a system actually does at runtime.
- **Keep `README.md` and this file in sync** with role/playbook changes — they're the source of truth for repo structure. (There is no separate `ROLES.md` — the detailed per-role table lives in `docs/ansible/roles.md`, which has its own staleness risk since it's not cross-checked automatically; verify against the Roles Reference table below or `roles/` directly if in doubt.)
- **Run the `humanizer` plugin on every Markdown doc in this repo before it's committed** (`docs/**/*.md`, `README.md`, role `README.md` files, `TODO.md`, any other `.md`) — `CLAUDE.md` is the only exemption. Applies to edits on existing docs too, not just newly created ones; `TODO.md` was missed for a while under a narrower reading of this rule (fixed 2026-08-09) since it's edited far more often than created.
- **No PHP, anywhere, ever.** No PHP application gets deployed to either cluster, evaluated as a homelab app candidate, or otherwise brought into this repo, regardless of feature fit or how good its Kubernetes/Helm story is. This is a hard exclusion from past experience running Drupal and WordPress, not a preference to weigh against other criteria — a PHP app is dropped from consideration on sight (see `docs/research/homelab-cloud-storage-comparison.md` for the Nextcloud example).

## Public Repository — Personal Data Policy

This repo (`kecsi-san/homelab`) is public. Treat personal identifiers (family names, gamertags, nicknames — not just credentials) with the same care as secrets:

- **Never commit a real personal identifier in plaintext**, even where it isn't a traditional secret (e.g. a family member's game username). Use the existing SealedSecret pattern (`kube-gitops/*/**/sealedsecret-*.yaml`) instead of templating the raw value into a Deployment env var or ConfigMap, even when the upstream tool's documented "easy" option requires embedding it directly.
- **Doc/code examples always use fully generic placeholders** (`alice`/`bob`/`example.com`/`example.net`) — never combine a real identifier that's already public elsewhere in this repo (e.g. the owner's own username) with other real personal details as if it were illustrative data. That reads as "just an example" and invites less scrutiny than clearly-real operational data would.
- **A forward-only fix isn't enough** if personal data already landed in a pushed commit — it stays reachable via `git log`/GitHub history until rewritten. Check `git log --all -- <path>` for prior exposure (not just HEAD), then rewrite with `git filter-repo` (older/multiple commits) or `commit --amend` + cherry-pick + force-push (a single recent commit), and force-push. This has happened twice in this repo's history.
- **`.hu` domain names never appear literal in Markdown**: the two personal `.hu` domains (registered at Integrity.hu, unrelated to the intentionally-public `kecskemethy.org` cluster domain used throughout this repo) get shortened to their first letter + `.hu` wherever they'd otherwise appear in a `.md` file — `k*.hu`, `l*.hu` — subdomains keep their prefix (`vault.k*.hu`, `mail.l*.hu`). Applies repo-wide: `docs/**/*.md`, `README.md`, role READMEs, `TODO.md`. `docs/howtos/ec2-rebuild-plan.md` and `ec2-ebs-volumes.md` already anonymize every hosted domain (`.com`/`.net`/`.hu` alike) via a `<d1>`/`<d2>` placeholder scheme; leave that convention as-is rather than converting it to `k*`/`l*`. Scope is Markdown only: non-Markdown files (`inventory/group_vars/aws_all.yml`/`local.yml`, `terraform/aws/main.tf`, `terraform/modules/eip/`, `kube-gitops/k8s/values/homepage.yaml`, `playbooks/local-cloud.yml`, and several role `defaults/main.yml`/task comments) still carry `linuxbox.hu`/`kecskemethy.hu` in plaintext by design, since those are real operational values Ansible/Terraform/ArgoCD template directly, not doc prose. Whether those should eventually route through Vault/`secrets.yml` instead is a separate, not-yet-decided question; see `TODO.md`.

## Common Commands

A `justfile` at the repo root wraps every command below as a `just <recipe>` — run `just --list`
to see them all grouped by area. The raw `ansible-playbook`/`terraform` invocations are kept here
as the source of truth the justfile mirrors; use whichever is more convenient.

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

# Gracefully shut down the whole k8s cluster (drains PVC-backed pods via the API
# using each pod's own terminationGracePeriodSeconds, then powers off all nodes)
ansible-playbook playbooks/shutdown-k8s.yml

# Nodes auto-uncordon a few minutes after boot (configure_k8s-auto-uncordon systemd timer,
# see post-k8s.yml) — this is the manual fallback if you don't want to wait or the timer failed
ansible-playbook playbooks/uncordon-k8s.yml

# Post-Kubernetes setup (Longhorn storage, Traefik, etc.)
ansible-playbook playbooks/post-k8s.yml

# Post-k3s setup (Traefik, Sealed Secrets, ArgoCD)
ansible-playbook playbooks/post-k3s.yml

# Configure MikroTik router DNS records
# Run BEFORE k8s.yml — api.k8s.<domain> must resolve to kube-vip before kubeadm init
# Also run after changing Traefik LB IPs or domain config
ansible-playbook playbooks/configure-router.yml

# Configure Cloudflare zone settings (ECH) and DNS A records
ansible-playbook playbooks/configure-cloudflare.yml

# OS upgrades on all kube group hosts
ansible-playbook playbooks/upgrade.yml

# AWS EC2 edge node — first-time setup (passwordless sudo not yet configured)
ansible-playbook --ask-become-pass -i inventory/aws_hosts playbooks/ec2-prerequisite.yml

# AWS EC2 edge node — base hardening (run after ec2-prerequisite.yml)
ansible-playbook -i inventory/aws_hosts playbooks/ec2-core.yml

# AWS EC2 edge node — web server (Apache2 + ModSecurity + ModEvasive + certbot)
ansible-playbook -i inventory/aws_hosts playbooks/ec2-web.yml

# AWS EC2 edge node — email server (Postfix + Dovecot + Rspamd + OpenDMARC + certbot)
# Run after ec2-web.yml — reuses the TLS cert Apache issues for mail_cert_name's domain
ansible-playbook -i inventory/aws_hosts playbooks/ec2-mail.yml

# AWS EC2 edge node — HashiCorp Vault (run after ec2-web.yml; manually init+unseal after first deploy)
ansible-playbook -i inventory/aws_hosts playbooks/ec2-vault.yml

# Terraform — EC2 infra (provision/update, also writes inventory/aws_hosts)
# cd terraform/aws && terraform init -backend-config=backend.conf && terraform apply

# Terraform — import existing resources (run once per resource)
# terraform import aws_instance.ec2 <instance-id>
# terraform import aws_eip.ec2 <eip-allocation-id>
# terraform import 'aws_route53_zone.zones["kecskemethy.com"]' <zone-id>
# terraform import 'aws_route53_zone.zones["kecskemethy.net"]' <zone-id>

# Typical full cluster rebuild timing (4-node homelab: 3 CP + 1 worker, Kubespray 2.31 + Cilium 1.18.5):
#   reset-k8s.yml   ~4 min
#   k8s.yml        ~21 min
#   post-k8s.yml    ~2 min
#   Total          ~27 min

# Full cluster rebuild runbook:
#   1. ansible-playbook playbooks/configure-router.yml   # ensure DNS resolves before kubeadm
#   2. ansible-playbook playbooks/reset-k8s.yml
#   3. ansible-playbook -b playbooks/k8s.yml
#   4. ansible-playbook playbooks/post-k8s.yml           # patches ArgoCD insecure mode automatically
#   5. kubectl apply -f ~/sealed-secrets-key-backup.yaml  # restore encryption key
#      kubectl rollout restart deployment sealed-secrets -n sealed-secrets
#      # ArgoCD will reconcile; any stuck pods (ContainerCreating) need a rollout restart
#      # once their SealedSecrets are decrypted
#   6. Firefox HSTS: after rebuild, delete SiteSecurityServiceState.bin from Firefox profile
#      folder (about:support → Open Profile Folder) to clear stale HSTS state
#   7. Verify Longhorn storage:
#      kubectl run longhorn-test --image=busybox --restart=Never \
#        --overrides='{"spec":{"volumes":[{"name":"data","persistentVolumeClaim":{"claimName":"longhorn-test"}}],"containers":[{"name":"longhorn-test","image":"busybox","command":["/bin/sh","-c","echo ok>/data/test && cat /data/test"],"volumeMounts":[{"name":"data","mountPath":"/data"}]}]}}' \
#        -- /bin/sh -c 'echo ok'
#      # easier: kubectl apply the PVC + pod manifest, check logs, then delete both

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
- `fileservers.yml` — targets `fileservers` group (remote hosts); baseline prerequisites/hardening (ssh, sudo, banner, etckeeper, git, ntp, minimal, network-tools, security-tools) plus shell comfort (oh-my-posh, fzf) and app-specific tooling (Node.js/thumbsup for prolion's photo gallery); no desktop/GUI roles (headless boxes)
- `personalise.yml` — localhost only; taste-driven setup (fonts, shell prompt, wallpapers, profile image)
- `prerequisite.yml` — must run before `k8s-nodes.yml`; sets up SSH keys and passwordless sudo
- `k8s.yml` / `reset-k8s.yml` — delegate entirely to the Kubespray collection
- `pre-k8s.yml` — runs after `prerequisite.yml` and before `k8s.yml`; prepares nodes (etckeeper)
- `post-k8s.yml` — runs after Kubernetes cluster is up; installs cluster-level tools (Longhorn, kube-extra, Traefik, Sealed Secrets, Headlamp)
- `post-k3s.yml` — runs after k3s install; installs ArgoCD then bootstraps GitOps (ArgoCD manages Traefik, Sealed Secrets, Headlamp via kube-gitops/k3s/)
- `configure-router.yml` — localhost only; upserts MikroTik DNS records and NAT rules via `configure_mikrotik-router` role; **must run before `k8s.yml`** so kubeadm can resolve the API VIP hostname (`api.k8s.<domain>`) during cluster init; also run after changing Traefik LB IPs, domain config, or port forwards
- `upgrade.yml` — OS package upgrades across all kube hosts
- `shutdown-k8s.yml` — cordons all kube nodes, gracefully deletes every PVC-backed pod cluster-wide (`kubectl delete pod --wait`, so each pod's own `terminationGracePeriodSeconds` applies instead of the kubelet-capped shutdown budget), then powers off all nodes; primary defense against corrupting stateful workloads (Prometheus WAL, CNPG Postgres) on shutdown — `kubelet_shutdown_grace_period` is the fallback for shutdowns that bypass this
- `uncordon-k8s.yml` — manual fallback companion to `shutdown-k8s.yml`; nodes normally auto-uncordon on their own a few minutes after boot via the `configure_k8s-auto-uncordon` systemd timer (see Roles Reference) — use this if you don't want to wait or the timer failed
- `backup-nfs.yml` — targets hppd600g6; carves 100G LV from existing VG, formats ext4, mounts at `/backups`, exports via NFS to 192.168.1.0/25, installs restic REST server as a systemd service storing repos in `/backups/restic-repos/`

**Playbook naming convention:**
- Lowercase, hyphens only (no underscores), `.yml` extension
- Categories and patterns:
  - Environment setup → `<target>.yml` (e.g. `local-core.yml`, `k8s-nodes.yml`)
  - Kubernetes cluster ops → `[<phase>-]<tool>.yml` (e.g. `k8s.yml`, `pre-k8s.yml`, `post-k8s.yml`, `reset-k8s.yml`, `post-k3s.yml`)
  - Maintenance → `<operation>.yml` (e.g. `upgrade.yml`, `prerequisite.yml`)
  - One-off operations → `<specific-action>.yml` (e.g. `dist-upgrade.yml`)

**Roles** (`roles/`) are the building blocks. The LEGO principle means roles should have no dependencies on each other. Add new functionality by writing a new role and including it in the appropriate playbook.

### Roles Reference

Quick-reference table below (kept in sync manually — see the Working Conventions note above). For role naming standard, the required directory/file layout, and status tracking for roles that aren't fully "done" (🔧 implemented-not-wired, 🚧 incomplete, 📋 planned), see `docs/ansible/roles.md`.

#### Active / Implemented

| Role | Purpose |
|------|---------|
| `configure_etc-hosts` | Manages `/etc/hosts` with kube group IPs and domain names |
| `configure_mikrotik-router` | Upserts static DNS records and NAT (dst-nat) rules on MikroTik router via `community.routeros` API; manages API VIP (`api.k8s.<domain>`), k3s wildcard, NFS alias, and port forwards |
| `configure_cloudflare-zone` | Manages Cloudflare zone settings (ECH) and DNS A records (e.g. `minecraft.<domain>`) via REST API; `proxied: false` for UDP services; credentials via `secrets.yml` |
| `configure_fzf` | Adds fzf initialization to `~/.bashrc` (idempotent); wired into `k8s-nodes.yml` and `fileservers.yml` (both gated by `fzf_enabled`) |
| `configure_ntp` | Disables systemd-timesyncd; installs chrony (Debian 13 dropped ntpd); configures MikroTik router as primary NTP + pool.ntp.org fallback; wired into `k8s-nodes.yml`, `fileservers.yml`, and `local-core.yml` (Linux only) with `ntp` tag |
| `configure_wsl2` | Templates full `/etc/wsl.conf` (`[automount]`/`[network]`/`[interop]`/`[user]`/`[boot]`, incl. `systemd = true`); WSL2-only (`ansible_kernel` detection), no-op elsewhere; wired into `local-core.yml` |
| `configure_mc-theme` | Downloads the gruvbox256 Midnight Commander skin to `~/.local/share/mc/skins/`; `mc` itself already installed by `setup_minimal`; wired into `personalise.yml` |
| `configure_git` | Templates `~/.gitconfig`; SSH-format commit signing (`gpg.format = ssh`, reuses the `github.com` key from `configure_ssh-client`, which must run first) — disabled on remote `k8s-nodes.yml`/`fileservers.yml` runs where no signing key is deployed |
| `setup_apt_repos` | Adds the Docker CE apt repo; installs `docker-ce` + compose plugin; adds `admin_user` to the `docker` group; wired into `local-core.yml` (`apt-repos`/`docker` tags) |
| `setup_iac-terraform` | Installs terraform, terraform-docs, tflint via Homebrew (`hashicorp/tap`); trivy is a role default but omitted here (handled by `setup_security-tools`); wired into `local-cloud.yml` |
| `setup_iac-extra` | Installs opentofu, terragrunt, terrascan, tfupdate via Homebrew; wired into `local-cloud.yml` |
| `setup_cloud-aws` | awscli, aws-sam-cli, session-manager-plugin via Homebrew; optional: okta-aws-cli, eksctl, aws-vault; wired into `local-cloud.yml` |
| `setup_cloud-azure` | azure-cli via Homebrew; optional: azd, bicep, azcopy, kubelogin; wired into `local-cloud.yml` |
| `setup_cloud-gcp` | google-cloud-sdk (gcloud/gsutil/bq) via Homebrew; optional: gke-gcloud-auth-plugin, cloud-sql-proxy; wired into `local-cloud.yml` |
| `setup_k3s` | Single-node k3s cluster — native install (Linux) or k3d (macOS, via Homebrew); wired into `k3s.yml`; see Kubernetes Setup below |
| `configure_bash-aliases` | Templates `~/.bash_aliases` (`eza`-based `ls`/`ll`/`l`/`la`, `alert`, `kx`/`kn`, `apt-maintenance`, `brew-maintenance`, `ecr-login`, `git-reset-author`); `k=kubectl` deliberately excluded, already owned by `setup_kube-extra` |
| `configure_ssh-client` | Templates `~/.ssh/config` from Vault (`workstation/ssh-config/<machine>`, keyed by `ansible_hostname`); fetches only the specific keys that machine's config references from a shared pool (`workstation/ssh-keys/<key-name>`), not the whole pool; runs interactively via the human's own cached Vault session, no AppRole |
| `configure_oh-my-posh` | Installs Pluto OMP theme; adds init block to `~/.bashrc`; wired into `k8s-nodes.yml` and `fileservers.yml` (both gated by `omp_enabled`) |
| `configure_ssh` | Deploys SSH authorized key for `ansible_ssh_user`; wired into `k8s-nodes.yml` and `fileservers.yml` |
| `configure_sudo` | Creates `/etc/sudoers.d/{user}` with NOPASSWD (visudo-validated); wired into `k8s-nodes.yml` and `fileservers.yml` (Linux only) |
| `configure_k8s-auto-uncordon` | systemd timer (`OnBootSec`, default 180s) + oneshot service on `kube_control_plane` nodes; waits per-node for `Ready` (default 300s timeout each) then uncordons — a stuck node stays cordoned instead of blocking the healthy ones; companion to `playbooks/shutdown-k8s.yml`'s cordon step; wired into `post-k8s.yml` |
| `debian_upgrade` | `apt update && upgrade && autoremove --purge`; wired into `k8s-nodes.yml` and `fileservers.yml` (both gated by `debian_upgrade_enabled`) |
| `disable_hibernation` | Creates `/etc/systemd/sleep.conf.d/nosuspend.conf`; masks sleep targets |
| `install_linuxbrew` | Installs Homebrew via `markosamuli.linuxbrew` (galaxy role, not vendored) |
| `install_nerd_fonts` | Installs Meslo LG + Fira Code Nerd Fonts via `homebrew_cask` |
| `setup_etckeeper` | Installs etckeeper; initialises git-backed `/etc` tracking; wired into `pre-k8s.yml` and `fileservers.yml` |
| `setup_legal_banner` | Copies `banner.txt` to `/etc/issue*`; clears MOTD; reloads sshd; wired into `k8s-nodes.yml` and `fileservers.yml` (both gated by `legal_banner_enabled`) |
| `setup_longhorn` | Installs iSCSI deps, longhornctl, and Longhorn via Helm |
| `setup_minimal` | Installs base + compression APT packages; optional brew base packages; wired into `k8s-nodes.yml` and `fileservers.yml` |
| `setup_network-tools` | Installs network diagnostic tools (APT on Linux, Homebrew on macOS); wired into `k8s-nodes.yml` and `fileservers.yml` (Linux only) |
| `setup_security-tools` | fail2ban + rkhunter (APT) + lynis (Cisofy repo) + trivy/hadolint (Homebrew); AIDE optional via `security_apt_packages` but excluded on `k8s-nodes.yml`/`fileservers.yml` — daily full-filesystem hash is too CPU/memory-heavy on kube nodes' dynamic storage and prolion's 7.3TB `/stuff` array |
| `setup_python-uv` | Installs uv CLI tools (checkov, ansible, black, etc.) and Python library packages into `~/.venv/devops`; optional `pyenv`/`pyenv-virtualenv` and `python-tk@<version>` |
| `setup_kube-extra` | Installs kubectl, helm (+ `helm-diff`, `helm-docs`), argocd, flux, kubeseal, krew via Homebrew; bash completion system-wide (Linux: `/etc/bash_completion.d/`; macOS: `bash-completion@2` + Homebrew completion dir); `k` alias for kubectl |
| `setup_traefik` | Installs Traefik ingress controller via Helm; `delegate_to: localhost`; kubeconfig per cluster |
| `setup_sealed-secrets` | Installs Sealed Secrets controller via Helm; cluster-specific key pair for encrypting secrets safe to commit |
| `setup_headlamp` | Installs Headlamp Kubernetes dashboard via Helm; captures manual homelab install; flips service to ClusterIP |
| `setup_argocd` | Installs ArgoCD via Helm (argo-helm chart); sets insecure mode for Traefik TLS termination; displays initial admin password |
| `setup_argocd-apps` | Applies `kube-gitops/{k3s,k8s}/root.yaml` once; ArgoCD self-manages all child apps after bootstrap |
| `setup_nfs-backup` | Carves LV from existing VG, formats ext4, mounts at `/backups`, installs + configures nfs-kernel-server; used by `backup-nfs.yml` targeting hppd600g6 |
| `setup_restic-rest-server` | Downloads restic REST server binary from GitHub releases, installs to `/usr/local/bin`, runs as systemd service on `:8000` storing repos in `/backups/restic-repos/`; `--no-auth` (LAN-only); used by `backup-nfs.yml` |
| `setup_go-dev-tools` | go, gopls, golangci-lint via Homebrew; optional: delve, goreleaser, ko, air |
| `setup_nodejs-dev-tools` | Node.js via nvm (multi-version, not a fixed brew formula), pnpm via Homebrew; optional brew + npm global packages |
| `setup_rust-dev-tools` | rustup + stable toolchain (rustc, cargo, rustfmt, clippy); optional cargo tools |
| `setup_vscode` | VS Code via apt (Linux) or Homebrew Cask (macOS); installs configured extensions; **`vscode_enabled: false` by default in `local-dev.yml`** — incomplete on WSL2, where VS Code runs on Windows, not Linux, so the extension-install step may not work as expected |
| `upgrade_brew` | `brew update && upgrade && cleanup` — cross-platform (Linux/macOS brew paths via vars/os/) |
| `upgrade_python-uv` | `uv tool upgrade --all` + `uv pip install --upgrade` in devops venv |
| `upgrade_nodejs` | Upgrades the nvm-managed Node.js version (`nvm install --reinstall-packages-from=current`) and global npm packages (`npm update -g`) |
| `upload_fav_bgimages` | Copies wallpapers to `/usr/share/backgrounds/`; generates GNOME background picker XML |
| `upload_profile_image` | Sets GNOME/GDM profile picture; image path set via `profile_image_src` variable (not stored in repo) |

| `setup_email-server` | Postfix (SMTP + submission 587 STARTTLS) + Dovecot (IMAPS 993) + Rspamd (spam + DKIM signing + greylisting + SPF) + OpenDMARC (inbound DMARC enforcement) + Postscreen (DNSBL connection filter) + certbot DNS-01 via Route53; virtual mailbox users from `secrets.yml`; multi-domain; DKIM keys generated via `rspamadm` and printed for Route53; OpenDMARC milter on port 25 only — submission uses Rspamd milter only |
| `setup_apache2` | Apache2 + ModSecurity (DetectionOnly) + ModEvasive + certbot DNS-01 via Route53; variable-driven vhosts supporting static sites, reverse proxy, and HTTPS redirect; `apache_vhosts` and `apache_certs` defined in `secrets.yml`; used by `ec2-web.yml` |
| `setup_users` | Creates named system users with home dirs, optional SSH authorized_keys, optional sudo group membership; `ec2_users` list defined in `secrets.yml`; `ec2_users_absent` removes accounts while preserving home dirs for data migration; wired into `ec2-core.yml` |
| `setup_vault` | Installs Vault via HashiCorp APT repo; deploys `/etc/vault.d/vault.hcl` (file storage backend, binds to 127.0.0.1:8200 with TLS disabled — Apache terminates TLS); package provides vault user and hardened systemd unit with `CAP_IPC_LOCK`; prints init/unseal instructions on every run; unseal keys and root token are NOT managed by Ansible |
| `setup_unbound` | Full recursive, DNSSEC-validating resolver on 127.0.0.1:53 — deliberately no forward-zone (a forward-only resolver like the AWS VPC resolver or Cloudflare can't be trusted to set the `ad` flag correctly, which would silently break DANE TLS verification in Postfix); disables systemd-resolved and writes a static `/etc/resolv.conf`; config validated with `unbound-checkconf` before apply; wired into `ec2-core.yml` |
| `setup_aws-ssm-agent` | Installs and enables the AWS SSM agent; gives an out-of-band rescue path (AWS Console → Session Manager) independent of sshd; requires `AmazonSSMManagedInstanceCore` attached to the instance's IAM role (not Ansible-managed); wired into `ec2-core.yml` |
| `configure_duo-ssh` | Migrates SSH MFA from `ForceCommand login_duo` to PAM-based `pam_duo.so`, scoped to sshd only via `/etc/pam.d/sshd` (never `common-auth`); `AuthenticationMethods publickey,keyboard-interactive`; validates with `sshd -t` before reload; `duo_ikey`/`duo_skey`/`duo_api_host` from `secrets.yml`; wired into `ec2-core.yml` |
| `configure_ssh-hardening` | Codifies sshd connection/session hardening (`MaxAuthTries`, `PermitRootLogin no`, `X11Forwarding no`, no TCP/agent forwarding, etc.) as a drop-in, replacing a hand-applied `lynis`-generated config; validates with `sshd -t` before reload; wired into `ec2-core.yml` |

#### Placeholder Roles (empty `tasks/main.yml`)

`setup_bichon` (Bichon email archive — Rust, IMAP pull from Dovecot, React UI; see `docs/research/email-archive-software.md`), `setup_email-tools`, `setup_mlops-tools`, `setup_aiops-tools`, `setup_mle-tools`

### Inventory Structure

`inventory/hosts` (gitignored — copy from `inventory/hosts.example`) defines:
- `local` group → `127.0.0.1` (localhost)
- `kube` group → physical servers (defined in `inventory/hosts`, gitignored)
- Kubernetes sub-groups under `k8s_cluster`: `kube_control_plane` (3 nodes), `kube_node` (4 nodes), `etcd` (3 nodes)
- `api.k8s` → `kube_vip_address` (Kubernetes API load balancer VIP via kube-vip, defined in `secrets.yml`)

Group variables in `inventory/group_vars/`:
- `all/all.yml` — Kubernetes cluster-wide settings (API server domain, load balancer)
- `all/secrets.yml` — **gitignored**; holds credentials and user-specific values (`ansible_ssh_user`, `admin_user`, AWS keys, Cloudflare tokens, `email_domains`, `mailbox_users`, `apache_certs`, `apache_vhosts`). Copy from `secrets.yml.example`.
- `all/vars.yml` — **committed**; holds non-sensitive infra values (`domain_name`, `upstream_dns_servers`, `kube_vip_address`, `kube_vip_interface`, `kube_control_plane_host`, `mikrotik_host`, Traefik IPs).
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
- `local-core.yml` tags: `brew`, `apt-repos`, `docker`, `apps`, `minimal`, `network`, `ntp`, `python`, `uv`, `ssh-client`, `bash-aliases`, `wsl2`
- `local-security.yml` tags: `sudo`, `apt-repos`, `security`, `checkov`
- `local-dev.yml` tags: `vscode`, `go`, `dev`, `nodejs`, `rust`, `gh`, `glab`
- `local-cloud.yml` tags: `iac`, `terraform`, `iac-extra`, `cloud`, `aws`, `azure`, `gcp`
- `local-kube.yml` tags: `kube`, `kubernetes`, `cloudflared`, `kind`
- `upgrade-local.yml` tags: `upgrade`, `apt`, `brew`, `uv`, `nodejs`
- `k8s-nodes.yml` tags: `update`, `ssh`, `hosts`, `banner`, `fonts`, `omp`, `fzf`, `gitconfig`, `hibernation`, `ntp`
- `fileservers.yml` tags: `update`, `ssh`, `sudo`, `banner`, `etckeeper`, `gitconfig`, `ntp`, `minimal`, `network`, `security`, `omp`, `fzf`, `nodejs`

Always tag new roles consistently so users can run them individually.

### Kubernetes Setup

Two strategies, two different targets:

**Kubespray — bare-metal multi-node cluster (`kube` group)**
- Uses `kubernetes-sigs/kubespray` collection (release-2.31 branch, installed via `requirements.yml`)
- HA control plane with kube-vip at `api.k8s.<domain_name>:6443`, Calico CNI, 3-node etcd
- Kubespray group vars live in `inventory/group_vars/` alongside custom role vars — same inventory serves both
- Post-cluster setup (`post-k8s.yml`) installs Longhorn distributed block storage via `setup_longhorn`

**k3s — single-node local dev cluster (localhost)**
- Linux (WSL2): native k3s via official installer script (`get.k3s.io`)
- macOS: k3s via k3d (k3s in Docker) installed through Homebrew — requires Docker Desktop or OrbStack
- Kubeconfig written to `~/.kube/k3s.yaml` and appended to `KUBECONFIG` in `~/.bashrc`; context renamed to `admin@k3s` automatically (Linux: from `default`; macOS: from `k3d-<cluster_name>`)
- Managed by `setup_k3s` role; playbooks: `k3s.yml` (install), `reset-k3s.yml` (uninstall)

### GitOps App Stack (k8s cluster, `kube-gitops/k8s/`)

ArgoCD manages all apps via app-of-apps pattern. Root app: `kube-gitops/k8s/root.yaml`.

ArgoCD itself is installed by the `setup_argocd` Ansible role (Helm, insecure mode) since it can't bootstrap itself; `argocd-config` below is the GitOps-managed follow-up that layers CM/RBAC/OIDC config on top.

| App | Namespace | Source | Purpose |
|-----|-----------|--------|---------|
| traefik | traefik | Helm (traefik) + values file | Ingress controller; LoadBalancer IP 192.168.1.101 via kube-vip |
| sealed-secrets | sealed-secrets | Helm (sealed-secrets) | Encrypts secrets safe to commit; key backup at `~/sealed-secrets-key-backup.yaml` |
| headlamp | headlamp | Helm (headlamp) | Kubernetes dashboard |
| argocd-config | argocd | Raw manifests (`kube-gitops/k8s/argocd/`) | ArgoCD CM/RBAC config, OIDC SealedSecret, ServiceMonitors — layered on top of the Ansible-installed ArgoCD |
| longhorn | longhorn-system | Helm (longhorn) | Distributed block storage; default StorageClass |
| cnpg | cnpg-system | Helm (cloudnative-pg) | PostgreSQL operator; `ServerSideApply=true` required (CRDs exceed 262 KB apply limit); `ignoreDifferences` on terminatingReplicas |
| cnpg-cluster | postgres | Raw manifests (`kube-gitops/k8s/cnpg/`) | 3-instance PostgreSQL cluster; 2Gi Longhorn PVCs; bootstrap DB `forgejo` owned by `forgejo`; DBs for `authentik`/`backstage`/`wikijs` via CNPG managed roles |
| forgejo | forgejo | Raw manifests (`kube-gitops/k8s/forgejo/`) | Git server + OCI registry + CI; rootless image; `GITEA__` env vars; admin user `kecsi`; `Recreate` rollout strategy (LevelDB queue lock); `ENABLE_REMEMBER_ME=false` |
| forgejo-runner | forgejo-runner | Raw manifests (`kube-gitops/k8s/forgejo-runner/`) | Forgejo Actions CI runner + cache-prune CronJob |
| authentik | authentik | Helm (charts.goauthentik.io) 2026.5.6 + raw manifests (`kube-gitops/k8s/authentik/`) | SSO/IDP; standalone redis:7-alpine; OAuth2 providers for Forgejo/Backstage/Wiki.js/ArgoCD/Grafana via Blueprint; `sub_mode: user_username` |
| backstage | backstage | Helm (backstage.github.io/charts) 2.8.2 + raw manifests (`kube-gitops/k8s/backstage/`) | Internal developer portal; custom image built from Forgejo OCI registry via Forgejo Actions CI; Postgres backend; Authentik OIDC login |
| wikijs | wikijs | Helm (charts.js.wiki) 3.0.0 + raw manifests (`kube-gitops/k8s/wikijs/`) | Self-hosted wiki (replaced Outline); Postgres backend; Authentik OIDC login with a session-fix ConfigMap patch for a `passport-openidconnect` bug |
| homepage | homepage | Helm (jameswynn/homepage) + values file | Start page dashboard |
| glance | glance | Raw manifests (`kube-gitops/k8s/glance/`) | Secondary dashboard widget page — weather, markets, Hacker News, Reddit, GitHub trending |
| ntfy | ntfy | Raw manifests (`kube-gitops/k8s/ntfy/`) | Push notification server; auth `deny-all`; `homelab` admin user |
| gatus | gatus | Helm (twin/gatus) + values + SealedSecrets dir | Uptime monitoring for 6 services; ntfy alerting |
| garage | garage | Raw manifests (`kube-gitops/k8s/garage/`) | S3-compatible object storage (Garage v2); `volsync-backups` bucket |
| volsync | volsync-system | Helm (backube/volsync) | PVC backup operator |
| volsync-config | volsync-system | Raw manifests (`kube-gitops/k8s/volsync-config/`) | Longhorn VolumeSnapshotClass |
| mealie | mealie | Raw manifests (`kube-gitops/k8s/mealie/`) | Self-hosted recipe manager; SQLite; default login changeme@example.com / MyPassword |
| opencloud | opencloud | Raw manifests (`kube-gitops/k8s/opencloud/`) | Self-hosted file storage and sharing (Go, ownCloud Infinite Scale fork); no database, filesystem-backed; Authentik OIDC (public client, PKCE); `homelab-admins` group maps to the OpenCloud `admin` role via `proxy.yaml`; LAN-only (no `external-dns` annotation); its own community Helm chart is archived, so this is hand-rolled raw manifests instead, see `docs/research/homelab-cloud-storage-comparison.md`; admin password sourced from Vault via an `ExternalSecret`, the pilot for the SealedSecrets→Vault migration (see `docs/howtos/vault-secrets-architecture.md`) |
| external-secrets | external-secrets | Helm (external-secrets.io) | Operator for the SealedSecrets→Vault migration; CRDs need `ServerSideApply=true` (exceed the 262KB apply limit, same class of issue as CNPG) |
| external-secrets-config | external-secrets | Raw manifests (`kube-gitops/k8s/external-secrets/`) | `ClusterSecretStore` pointing at the `homelab/` Vault KV mount via AppRole auth, plus the one bootstrap SealedSecret holding ESO's own AppRole `secret_id` |
| minecraft | minecraft | Raw manifests (`kube-gitops/k8s/minecraft/`) | Minecraft Bedrock server; `itzg/minecraft-bedrock-server`; UDP 19132 on 192.168.1.110 (kube-vip); 5Gi Longhorn PVC |
| pod-cleanup | kube-system | Raw manifests (`kube-gitops/k8s/pod-cleanup/`) | Nightly CronJob (03:00) deleting Failed + Succeeded pods cluster-wide; RBAC: list+delete pods |
| reloader | reloader | Helm (stakater/reloader) | Rolls pods on ConfigMap/Secret change |
| kube-prometheus-stack | monitoring | Helm (prometheus-community) | Prometheus + Alertmanager, scraping cluster + 4-node Debian `node_exporter`, ntfy webhook bridge; removed 2026-08-08 to free Longhorn disk space on `hped800g5` during a Postgres outage, reinstalled 2026-08-09 with `retentionSize` capped at 10GB (was unbounded 45GB); apiserver/etcd/controller-manager/scheduler scrape noise dropped same day (apiserver kept, filtered to just `kubernetes_build_info` for kromgo's badge; the other three fully disabled) cut TSDB active series ~65%, PVC now 15Gi (was 50Gi) |
| grafana-operator | monitoring | Helm (grafana.github.io) | Grafana via operator CRDs; Authentik OAuth2 login; dashboards: Node summary, Longhorn, Traefik, ArgoCD |
| monitoring-config | monitoring | Raw manifests (`kube-gitops/k8s/monitoring/`) | Grafana instance/dashboard CRDs; ServiceMonitors for Longhorn/Traefik |
| kromgo | monitoring | Raw manifests (`kube-gitops/k8s/kromgo/`) | Public status badges (`kromgo.kecskemethy.org`) reading Prometheus/Alertmanager: debian_version, kubernetes_version, alerts, argocd_out_of_sync, failed_pods, cpu, memory, longhorn_storage, node_count, pod_count, birth_age, uptime_age |
| cert-manager-config | cert-manager | Raw manifests (`kube-gitops/k8s/cert-manager/`) | ClusterIssuer (Let's Encrypt DNS01 via Cloudflare) + Cloudflare API token SealedSecret |
| cloudflared | cloudflared | Raw manifests (`kube-gitops/k8s/cloudflared/`) | Cloudflare Tunnel daemon (2 replicas) routing `*.<your-domain.tld>` → Traefik via `noTLSVerify: true`; see dual-path TLS notes below |
| external-dns | external-dns | Helm (kubernetes-sigs.github.io/external-dns) + values file | Watches IngressRoute `external-dns.alpha.kubernetes.io/target` annotations and syncs matching Cloudflare CNAME records to the cloudflared tunnel; `policy: sync` (deletes records when IngressRoutes are removed); `--cloudflare-proxied` |
| external-dns-config | external-dns | Raw manifests (`kube-gitops/k8s/external-dns/`) | Cloudflare API token SealedSecret for external-dns |
| ingressroutes | argocd | Raw manifests (`kube-gitops/k8s/ingressroutes/`) | All Traefik IngressRoute + cert-manager Certificate objects, one pair per service; carries the external-dns target annotation |

**VolSync backup architecture:**
- Restic REST server runs on hppd600g6 (192.168.1.52:8000) — external to k8s, data on 100G LV at `/backups/restic-repos/`
- DNS alias: `backups.kinet.local` → 192.168.1.52
- ntfy PVC (`ntfy/ntfy-data`) → backed up daily 02:00 → `rest:http://192.168.1.52:8000/ntfy`
- gatus PVC (`gatus/gatus`) → backed up daily 03:00 → `rest:http://192.168.1.52:8000/gatus`
- mealie PVC (`mealie/mealie-data`) → backed up daily 04:00 → `rest:http://192.168.1.52:8000/mealie`
- minecraft PVC (`minecraft/minecraft-data`) → backed up weekly Sunday 05:00 → `rest:http://192.168.1.52:8000/minecraft`
- `copyMethod: Clone` (Longhorn CSI clone; Snapshot requires Longhorn backup target which is not configured)
- Retention: 6 hourly, 7 daily, 4 weekly, 3 monthly; prune every 14 days
- Restic credentials stored as SealedSecrets per namespace (`volsync-restic-secret`)

**Pod garbage collection:**
- `kube_controller_terminated_pod_gc_threshold: 20` set in `inventory/group_vars/k8s_cluster/k8s-cluster.yml`; takes effect after next `k8s.yml` run (Kubespray pushes flag to kube-controller-manager)
- `pod-cleanup` CronJob (kube-system, 03:00 daily) deletes all `Failed` and `Succeeded` pods cluster-wide as a second layer; `Succeeded` pods accumulate from VolSync backup jobs
- Manual cleanup: `kubectl delete pods -A --field-selector=status.phase=Failed`

**SealedSecrets workflow:**
```bash
# Always seal against the k8s cluster context (admin@k8s), not the k3s context (admin@k3s)
kubectl create secret generic my-secret --namespace my-ns \
  --from-literal=KEY=value --dry-run=client -o yaml | \
  kubeseal --format yaml \
    --context "admin@k8s" \
    --controller-name sealed-secrets \
    --controller-namespace sealed-secrets > sealedsecret.yaml
# Add yamllint disable-line comments before long encrypted data lines
```

**Authentik operational notes:**
- Blueprint discovery is periodic — after ConfigMap changes, restart the worker pod or run: `kubectl exec -n authentik deployment/authentik-worker -- ak apply_blueprint /blueprints/custom/forgejo.yaml`
- Blueprints require `invalidation_flow` field (added in 2026.x): `!Find [authentik_flows.flow, [slug, default-provider-invalidation-flow]]`
- Create users via ak shell: see `docs/IDP/user-management.md`; no `create_user` CLI command exists
- `akadmin` is the bootstrap admin; use it only for IDP management, not day-to-day logins
- Bitnami Redis removed from Docker Hub — use standalone `redis:7-alpine` deployment named `authentik-redis-master`
- **Always set `grant_types` explicitly** on every `authentik_providers_oauth2.oauth2provider` blueprint entry (`[authorization_code, refresh_token]`, plus `client_credentials` for machine-to-machine) — 2026.5.0 changed the default from "all types" to `[]`; a provider with empty `grant_types` still resolves `client_id` but fails every authorization attempt with an unhelpful `invalid_request`
- When an OIDC login fails silently (no error logged), check for an **issuer mismatch first** before instrumenting deeper — most OIDC clients call `fail()` not `error()` on `claims.iss` mismatch, so nothing gets logged. Compare `<provider>/.well-known/openid-configuration`'s `issuer` against the client's configured value; Authentik's `issuer_mode: global` vs `per_provider` changes what `iss` actually is

**Traffic and TLS architecture (dual-path):**
- **LAN path (Edge browser):** MikroTik wildcard DNS `*.<your-domain.tld>` → 192.168.1.101 (Traefik); cert-manager issues per-service Let's Encrypt certs via DNS01 (Cloudflare API token); IngressRoutes reference `<service>-tls` secrets; no H2 coalescing since each service has its own cert
- **Cloudflare path (Firefox + WARP):** Cloudflare WARP routes traffic through Cloudflare edge → Cloudflare Tunnel CNAME (`<tunnel-id>.cfargotunnel.com`) → `cloudflared` pod (2 replicas, `kube-gitops/k8s/cloudflared/`) → Traefik via `https://traefik.traefik.svc.cluster.local` with `noTLSVerify: true`; Cloudflare's Universal SSL cert is what the browser sees
- **DNS automation for the Cloudflare path:** the `external-dns` app (ArgoCD-managed Helm chart, ArgoCD app `external-dns`) watches every IngressRoute's `external-dns.alpha.kubernetes.io/target: "<tunnel-id>.cfargotunnel.com"` annotation and syncs the matching proxied Cloudflare CNAME record automatically — `policy: sync`, so it also deletes the record if the IngressRoute is removed; every service in `kube-gitops/k8s/ingressroutes/` carries this annotation, so both paths (LAN cert-manager DNS01 + Cloudflare Tunnel CNAME) are provisioned per-service without manual DNS edits. **Miss the annotation on a new IngressRoute and the service is unreachable from the internet** — `external-dns` has no CNAME to write and either skips the record or falls back to the LAN IP, which Cloudflare's edge can't reach.
- cert-manager: installed via ArgoCD app (`cert-manager-config.yaml`); ClusterIssuer uses DNS01 challenge with `cloudflare-api-token` SealedSecret in `cert-manager` namespace
- ArgoCD runs in insecure mode; TLS terminated at Traefik (LAN) or Cloudflare edge (WARP)
- MikroTik wildcard DNS entry for `<your-domain.tld>` (match-subdomain) defined in `configure_mikrotik-dns` defaults; run `configure-router.yml` after any IP/domain changes

### GitOps App Stack (k3s cluster, `kube-gitops/k3s/`)

ArgoCD manages all apps via app-of-apps pattern. Root app: `kube-gitops/k3s/root.yaml`.

| App | Namespace | Source | Purpose |
|-----|-----------|--------|---------|
| traefik | traefik | Helm (traefik) + values file | Ingress controller; `tls: {}` IngressRoutes (k3s default TLS store); built-in k3s Traefik must be disabled first |
| sealed-secrets | sealed-secrets | Helm (sealed-secrets) | Secrets encryption; **re-seal against `admin@k3s` context** |
| headlamp | kube-system | Helm (headlamp) + values file | Kubernetes dashboard |
| argocd-config | argocd | Raw manifests (`kube-gitops/k3s/argocd/`) | ArgoCD CM/RBAC config, OIDC SealedSecret — layered on top of the Ansible-installed ArgoCD, same pattern as k8s |
| homepage | homepage | Helm (jameswynn/homepage) + values file | Start page (`kube-gitops/k3s/values/homepage.yaml`) |
| cert-manager | cert-manager | Helm (cert-manager) + config manifests | Let's Encrypt DNS01 certs via Cloudflare; wildcard cert `*.k3s.<your-domain.tld>` |
| cert-manager-config | cert-manager | Raw manifests (`kube-gitops/k3s/cert-manager/`) | ClusterIssuer + wildcard Certificate |
| reloader | reloader | Helm (stakater/reloader) | Rolls pods on ConfigMap/Secret change |
| cnpg | cnpg-system | Helm (cloudnative-pg) | PostgreSQL operator; same `ServerSideApply=true` + `ignoreDifferences` fixes as k8s |
| cnpg-cluster | postgres | Raw manifests (`kube-gitops/k3s/cnpg/`) | Single-instance PostgreSQL; `local-path` storage; 2Gi PVC; DBs for authentik/forgejo/wikijs |
| forgejo | forgejo | Raw manifests (`kube-gitops/k3s/forgejo/`) | Git server; same rootless image + `GITEA__` env var pattern as k8s; domain `forgejo.k3s.kecskemethy.org`; own IngressRoute inside its app dir (not the shared `ingressroutes/` app) |
| forgejo-runner | forgejo-runner | Raw manifests (`kube-gitops/k3s/forgejo-runner/`) | Forgejo Actions CI runner |
| authentik | authentik | Helm (charts.goauthentik.io) 2026.5.6 + raw manifests (`kube-gitops/k3s/authentik/`) | SSO/IDP; fully deployed (own Blueprint ConfigMap, standalone redis, 4 OAuth2 SealedSecrets) — **not** synced from the k8s stack; independent instance, same as k8s architecturally |
| wikijs | wikijs | Helm (charts.js.wiki) 3.0.0 + raw manifests (`kube-gitops/k3s/wikijs/`) | Wiki; same Authentik OIDC session-fix patch as k8s |
| ingressroutes | argocd | Raw manifests (`kube-gitops/k3s/ingressroutes/`) | Traefik IngressRoutes + `tlsstore.yaml` for argocd/authentik/headlamp/homepage/traefik-dashboard/wikijs |

**k3s vs k8s differences:**
- Storage class: `local-path` (not Longhorn) — single node, no replication
- CNPG: `instances: 1` (single node)
- IngressRoutes: `tls: {}` (k3s default TLS store, no per-cert secret reference)
- No VolSync backups, no Garage, no ntfy/gatus/mealie/minecraft/monitoring/backstage/glance on k3s — dev/IDP stack only
- No Cloudflare Tunnel/external-dns on k3s — LAN-only, no internet-facing path
- SealedSecrets sealed with `--context admin@k3s`; incompatible with k8s-sealed secrets

**SealedSecrets workflow (k3s):**
```bash
kubectl create secret generic my-secret --namespace my-ns \
  --from-literal=KEY=value --dry-run=client -o yaml | \
  kubeseal --format yaml \
    --context "admin@k3s" \
    --controller-name sealed-secrets \
    --controller-namespace sealed-secrets > sealedsecret.yaml
# Add yamllint disable-line comments before long encrypted data lines
```

## Known Gotchas

Non-obvious failure modes hit in this repo, worth checking before re-diagnosing the same class of bug from scratch.

### Ansible

- **Play-level `become`**: set `become: false` at the play level, explicit `become: true` per `import_role`/task that needs root. Play-level `become: true` runs fact-gathering as root too, which resolves `ansible_env.HOME` to `/root` and breaks user-space roles.
- **`--check` isn't always side-effect-free**: the `git` module does real clone/fetch work under `--check` when the destination doesn't exist yet (hit via `install_linuxbrew`'s vendored `markosamuli.linuxbrew` role on a host with no prior brew install). `--skip-tags always` also disables Ansible's automatic "Gathering Facts" task, since that implicit task is itself tagged `always` — to skip one specific `always`-tagged task, use `--start-at-task="<expanded task name>"` instead.
- **Kubespray control-plane arg changes need `-e upgrade_cluster_setup=true`**: a plain `ansible-playbook -b playbooks/k8s.yml` run silently no-ops any `kube_apiserver_*`/`kube_controller_*`/`kube_scheduler_*` extra_arg change in `k8s-cluster.yml` — Kubespray gates the `kubeadm upgrade apply`-equivalent step behind this flag. Restarts control-plane pods one node at a time; kube-vip keeps the API VIP available throughout, so it's safe to run. Verify against the live static pod's actual command, not just a clean playbook run.
- **`install_linuxbrew` must run before any brew-dependent role** on a remote-host playbook (`setup_minimal`'s brew packages, `setup_security-tools`'s trivy/hadolint) — neither has an install fallback, they assume brew already exists.
- **Pin volatile Homebrew formulas**: an unpinned formula (`state: present`, no version) can silently major-version-bump on `upgrade-local.yml`'s `brew upgrade`. Helm did exactly this (3→4) and broke ArgoCD's Server-Side-Apply assumptions — it's now pinned (`helm@3` + `brew pin`) in `setup_kube-extra`; apply the same pattern to any other tool where a breaking major bump would hurt.
- **Third-party Homebrew taps need the fully-qualified name everywhere** (`hashicorp/tap/terraform`, not `terraform`) — the bare name triggers Homebrew's untrusted-tap gate on formula *resolution*, even when the package is already installed under the short name.
- **Custom callback plugin overrides need the full `DOCUMENTATION` block** copied from the original, even if no options change — without it, `set_options()` fails silently (no error, just no output).
- **`ansible-lint` stays CI-only**, never pre-commit — it's ~70s/run, too slow for a commit hook. `yamllint` (~1s) is what's actually in the pre-commit config.
- **Jinja2 `.dict.items` is Python's `dict.items()` method, not the JSON key `"items"`**: `kubectl -o json` output has a top-level `items` key holding the object list, but `{{ some_dict.items }}` resolves via dot-attribute lookup to the built-in method and fails as a loop source (`Invalid data passed to 'loop'`). Use bracket notation: `{{ some_dict['items'] }}`. Applies to any dict key that collides with a dict method name (`items`, `keys`, `values`, `get`, `update`, ...).

### GitOps / ArgoCD

- **Verify CRD field nesting with `kubectl explain`** before editing a manifest (VolSync `ReplicationSource`, CNPG `Cluster`, cert-manager `ClusterIssuer`, ArgoCD `Application`, etc.) — a wrong nesting level is silently pruned by the CRD's structural schema. `kubectl apply` reports success and `git diff` shows the change, but the live object never gets it. Re-read the live object right after applying to confirm the field actually landed.
- **App-of-apps self-heal**: pausing sync on a child Application isn't enough for manual live edits (scale to 0, `kubectl edit`) — root also has `selfHeal: true` and re-pushes the child's `syncPolicy.automated` from git within seconds, undoing the child's own paused state. Pause both root and the child (`kubectl patch application -n argocd <app> --type merge -p '{"spec":{"syncPolicy":{"automated":null}}}'`); to restore, only patch root back — the child inherits it on root's next reconcile.
- **ArgoCD secrets referenced in `argocd-cm`** (`$secret-name:key`) need the label `app.kubernetes.io/part-of: argocd` or they're silently ignored — ArgoCD sends an empty client secret and the OAuth2 provider returns `invalid_client`.
- **`configure_mikrotik-router` never deletes DNS records** — only adds/updates (`api_find_and_modify`/`api`). Stale records must be removed manually via Winbox/SSH. RouterOS also processes static entries top-to-bottom — more specific match-subdomain entries (e.g. `k3s.<domain>`) must be ordered before broader wildcards (`<domain>`) or the wildcard wins.
- If an Application stays `OutOfSync` despite a correctly-configured `ignoreDifferences`, check for **stale live-only drift first** (e.g. a leftover `kubectl.kubernetes.io/restartedAt` annotation from a manual `kubectl rollout restart`, never tracked by git) before fighting the ignore-rule syntax further — removing the drift at the source has proven more reliable than tuning `jqPathExpressions`/`jsonPointers`.
- Avoid OCI Helm chart sources (`oci://`) from Gitea-based registries (e.g. codeberg.org) in ArgoCD — the `/v2/` health check returns 401 even for public packages, and ArgoCD marks the repo broken, blocking sync entirely (the chart still pulls fine via plain `helm` CLI). Use a standard HTTP Helm repo, or raw Kubernetes manifests, instead.
- Homepage v1.2.0+'s Kubernetes integration selects pods via the `app.kubernetes.io/name` label, not the plain `app` label — any new raw-manifest deployment that needs a Homepage status badge needs both labels set.
- SPAs that make background `fetch()` calls for streaming/live data (not just full-page navigation) can break behind Traefik `forwardAuth` via CORS on the redirect, even though the middleware is correctly configured and the main page loads fine — the failure looks like "page loads, then breaks," not an obvious auth error. Check for this (DevTools Network tab, repeated XHR/fetch after load) before assuming SSO will "just work" on a new service's frontend.
- **Two installers can silently fight over the same ArgoCD install**: Kubespray ships its own `kubernetes-apps/argocd` role (`argocd_enabled` in `inventory/group_vars/k8s_cluster/addons.yml`), which downloads the raw upstream `install.yaml` and applies it via `kubectl` on every `k8s.yml` run, pinned to its own `argocd_version`, completely unaware of the Helm-managed install `roles/setup_argocd` runs from `post-k8s.yml`. With both enabled, every `k8s.yml` rerun reapplies Kubespray's raw manifests over the Helm release, at Kubespray's pinned version, with no `meta.helm.sh/*` ownership annotations — this is exactly how the k8s cluster's ArgoCD silently lost its Helm release tracking (found 2026-09-06: zero `sh.helm.release.v1.argocd.*` secret, no ownership labels on any resource in the namespace, running an image version matching only Kubespray's pin, not the Helm chart's). Fixed by setting `argocd_enabled: false` in `addons.yml` (Kubespray's own default already, this repo had it flipped to `true`) and adding `take_ownership: true` (Helm ≥3.17) to `setup_argocd`'s install task to reclaim the existing unmanaged resources in one upgrade. k3s has no equivalent addon and was never affected.

### Kubernetes / Storage & Networking

- **A stuck/inactive CNPG replication slot silently blocks WAL recycling**, not just replication — if a replica falls onto a stale timeline and stops streaming (check its logs for `Refusing to restore future timeline history file` / `record with incorrect prev-link`), its slot stays `active: false` at a fixed `restart_lsn` on the primary, and Postgres retains WAL past `max_wal_size` indefinitely instead of self-capping. This can fill a PVC sized only for real table data (a 2Gi PVC with ~200MB of actual data still hit 100%). Check `pg_replication_slots` on any live instance when a CNPG cluster reports disk pressure, don't assume the data itself grew.
- **A CNPG auto-failover during this homelab's routine simultaneous multi-node reboot can leave the demoted old primary silently stuck on the previous WAL timeline**, feeding directly into the gotcha above. A PostgreSQL promotion always mints a new timeline; if the outgoing primary comes back moments after a replacement was already promoted, it can refuse to trust the new timeline's history file instead of cleanly rejoining as a replica. CNPG's own Cluster status doesn't catch this — it only checks that the pod is `Running` and the instance-manager API responds, so it labels the pod `replica` and moves on without ever confirming it's actually streaming. Root-caused 2026-08-17 by grepping the `cnpg-cloudnative-pg` operator pod's own logs (`grep -iE "postgres-3|promot|timeline|primary|failover"`) for the reboot window the day before, which showed the exact `"Current primary isn't healthy, initiating a failover"` → `"Failing over"` → old-primary-reattached sequence; the stuck replica sat undetected for ~30 hours until its blocked slot filled the primary's disk. Check `pg_replication_slots` after any multi-node reboot, not just once disk pressure already shows up.
- **Longhorn refuses PVC expansion below its per-disk reserved-free floor** (default 25% of the disk's `storageMaximum`, via the `validator.longhorn.io` admission webhook) — even a `resizeInUseVolumes: true` CNPG cluster with a correctly-bumped `spec.storage.size` in git will silently fail to actually grow the PVCs it's blocked on (the operator's `ensure_sufficient_disk_space` reconciler just loops, logging "cannot proceed until the PVC group is enlarged," without erroring). Check `kubectl get nodes.longhorn.io <node> -n longhorn-system -o json` → `.status.diskStatus.<disk>.storageAvailable` against 25% of `storageMaximum` before assuming a `spec.storage.size` bump alone will unblock a full PVC; a `kubectl patch pvc` attempt surfaces the exact shortfall in the webhook's rejection message. Freeing real usage elsewhere on that same disk (or evicting a replica to another node) is the fix, not a bigger `size:` request.
- **CNPG won't grow a PVC out from under a pod that can't start** — if the workload pod is crash-looping specifically *because* its disk is full, don't wait on the operator to reconcile the resize automatically; it can deadlock (no healthy instance to coordinate the resize through). `kubectl patch pvc <name> --type merge -p '{"spec":{"resources":{"requests":{"storage":"<newSize>"}}}}'` directly is safe once the StorageClass (`allowVolumeExpansion: true`) and the Cluster CR's `spec.storage.size` already agree on the target — you're just completing what the operator should have done.
- **Deleting a CNPG instance's pod + PVC to force a rebuild is racy if done as two sequential commands** — the operator can recreate the pod (same name) fast enough to remount the old PVC before its `kubernetes.io/pvc-protection` finalizer clears, leaving it stuck `Terminating` with `Used By: <pod>` pointing at the very pod you just recreated. Force-delete the pod (`--grace-period=0 --force`) first, *then* strip the PVC's finalizer (`kubectl patch pvc <name> --type merge -p '{"metadata":{"finalizers":null}}'`) — only then does the operator provision a genuinely fresh PVC and trigger a real base-backup join.
- **A recreated pod (new IP, new Cilium identity) can leave *other*, unrelated pods unable to reach it** — pods that already had an open/cached connection to the old identity can fail fresh connection attempts with `connect: operation not permitted` (not `connection refused`) even though a brand-new pod elsewhere in the cluster reaches the same Service fine. Hit this three times in one incident (Traefik → Authentik outpost, Authentik → Postgres, Wiki.js → Postgres) after CNPG recreated a primary pod. Fix is a plain `kubectl delete pod` on the *stuck* side (not the recreated target) to force fresh network state — no CNI/policy misconfiguration involved, just stale state that a restart clears.

### Terraform & Vault

- **`skip_child_token = true`** on every `provider "vault" {}` block — the provider tries to mint an ephemeral child token by default (needs `auth/token/create`, which none of this repo's Vault policies grant), even for reads/writes the token already has direct access to. Fixing a 403 here means adding this flag, not broadening policy grants.
- **One tool owns a given DNS record type, permanently** — never have Ansible (or any generator) call a DNS provider API directly for a record Terraform could also touch, even during a migration window. The value flows through Vault instead, and Terraform stays the sole API caller for that provider.
- **`vault_kv_secret_v2` data sources pull the entire secret payload into Terraform state**, not just the field referenced in `.tf` code — the provider marks the attribute sensitive (redacted from CLI/plan output), but the full payload still lands in the state file in plaintext. If a public field (e.g. an SSH public key) is co-located with a private one at the same Vault path, reading it for the public field still leaks the private one into state — split co-located secrets across separate KV paths before any Terraform data-source read. Once split, wrap a field that's genuinely public in `nonsensitive(...)` if you need it to render in plan output (e.g. for a public DNS record value) — never do this for real credential material.
- For a multi-chunk Route53 TXT value (>255 bytes, e.g. a DKIM key), build the chunk list and `join('" "')` — **no leading/trailing quote**. Terraform/the AWS provider adds one outer quote pair automatically; wrapping each chunk yourself produces a doubled-quote string the API rejects.
- Import existing AWS security groups as `aws_security_group_rule` resources, never inline `ingress`/`egress` blocks inside `aws_security_group` — inline blocks produce noisy diffs on import (description/IPv4-IPv6 mismatches show as changes even when rules are identical); rule resources are also more granular for future additions.

### Dependency management (Renovate)

- Renovate does **not** track two things in this repo: image tags pinned directly in per-app Helm values files (needs an explicit `helm-values` manager scoped to `kube-gitops/*/values/*.yaml`, plus `image.repository` present alongside any bare `image.tag`), and ArgoCD's own chart version (`argocd_chart_version` in `roles/setup_argocd/defaults/main.yml` — outside the `kube-gitops/` tree Renovate scans; a manual periodic check, tracked in `TODO.md`).
- `.github/dependabot.yml` is intentionally empty — Renovate handles all dependency updates (see `renovate.json`). Old pre-migration Dependabot PRs can still be open and duplicate a later Renovate grouped PR for the same package; check for supersession before merging both.
