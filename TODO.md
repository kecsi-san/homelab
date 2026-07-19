# TODO

Planned work, known issues, and ideas. Check here before starting a new session.

## Active / Next up

- [ ] **Helm 4 migration** — workstation `helm` was unpinned and silently drifted to v4.2.3 via `brew upgrade` (`upgrade-local.yml`); pinned back to `helm@3` (3.21.3) in `roles/setup_kube-extra/tasks/main.yml` on 2026-07-19 to unblock `post-k3s.yml`. Root cause of the break: Helm 4 enforces strict Kubernetes Server-Side-Apply field-manager ownership instead of Helm 3's lenient 3-way merge — `argocd-cm`/`argocd-rbac-cm` are co-managed by the ArgoCD Helm chart *and* ArgoCD's own self-referential `argocd-config` GitOps Application (writes `oidc.config`/`url`/`policy.csv`), and Helm 4 refuses the overlap. Before ever re-attempting Helm 4: (1) fix the ArgoCD chart values so it stops templating those specific ConfigMap keys, leaving `argocd-config` as sole owner, (2) audit `setup_traefik`/`setup_sealed-secrets`/`setup_headlamp`/`setup_longhorn` for the same class of dual-ownership conflict before their next Helm upgrade — none hit it yet, but all use the same `kubernetes.core.helm` + separate-raw-manifest pattern that caused this. Kubespray's own Helm on the kube nodes (`/usr/local/bin/helm`, v3.18.4) is unaffected — separate install mechanism, already pinned by Kubespray's release branch.

- [ ] **Cilium Hubble UI** — noticed the container image being pulled during a `k8s.yml` run (Kubespray deploys it as part of the Cilium addon); make it reachable/visible from Homepage instead of leaving it unexposed

- [ ] **Backstage Kubernetes plugin** — shows "Entity context is not available" as a standalone nav item; either configure it for catalog entities (requires annotations) or remove `kubernetesPlugin` from `App.tsx`
- [x] **Kromgo** — badges live on GitHub README; 12 metrics: versions, nodes, pods, failed pods, CPU, memory, Longhorn storage, birth age, uptime age, alerts, ArgoCD out-of-sync
- [ ] **VictoriaLogs** — log aggregation (no log storage currently); single-binary replacement for Loki, significantly lower RAM, simpler to operate; community is moving away from Loki toward VictoriaLogs; deploy alongside kube-prometheus-stack; Fluent Bit or Grafana Alloy as log forwarder
- [ ] **TargetDown alert** — investigate what Prometheus target is actually down (wasn't confirmed firing yet)
- [ ] **`kube_controller_terminated_pod_gc_threshold: 20`** — set in `inventory/group_vars/k8s_cluster/k8s-cluster.yml` but needs `ansible-playbook -b playbooks/k8s.yml` rerun to actually take effect on kube-controller-manager (same `k8s.yml` run as the graceful shutdown item below covers this too)
- [ ] **Graceful Node Shutdown** — `kubelet_shutdown_grace_period: 120s` / `kubelet_shutdown_grace_period_critical_pods: 30s` added to `inventory/group_vars/k8s_cluster/k8s-cluster.yml` (2026-07-19) so `ansible kube -a "sudo shutdown -h now"` lets kubelet gracefully drain pods (incl. Longhorn instance-manager/replicas) before poweroff instead of systemd killing containerd/kubelet abruptly, which was leaving Longhorn replicas dirty and forcing rebuilds on next boot (root-caused after a real power-loss event that morning). `ansible-playbook -b playbooks/k8s.yml` run in progress to push it — confirm kubelet config applied on all 4 nodes once done
- [ ] **PR #37 `chore(helm): Update helm charts`** — clean/mergeable (6 Helm chart bumps across k3s+k8s: authentik, cert-manager, cnpg, reloader, sealed-secrets, traefik, kube-prometheus-stack; all patch/minor, no majors); holding merge until the in-progress `k8s.yml` run above finishes so we don't stack two live-cluster changes at once

## Periodic checks

Recurring maintenance — not one-off tasks; re-verify occasionally rather than checking off.

- **Kubernetes cluster upgrade** — Kubespray pinned to `release-2.31` in `requirements.yml`, running Kubernetes v1.35.4 on all 4 nodes (checked 2026-07-05). Check https://github.com/kubernetes-sigs/kubespray/releases for newer release branches supporting a newer Kubernetes minor version; rerun `ansible-galaxy install -r requirements.yml -f` then `ansible-playbook -b playbooks/k8s.yml` to upgrade. Not Renovate-tracked (git dependency in `requirements.yml`, not a package manager Renovate understands here).

- **ArgoCD version** — `argocd_chart_version` in `roles/setup_argocd/defaults/main.yml` is a plain Ansible default, not tracked by Renovate; the two clusters only upgrade when someone reruns `post-k8s.yml`/`post-k3s.yml` after bumping it, so they can silently drift apart. Check https://github.com/argoproj/argo-helm for newer releases and confirm both clusters still match. Last checked 2026-07-05: k8s v2.14.5 (chart 7.7.5), k3s v2.13.1 (older chart pin — reran less recently).

## AWS / EC2 & Email

- [ ] **EC2 rebuild — Phase 6** — new instance provisioning + data migration + EIP cutover + old-instance decommission; Phases 1–5 (all Ansible roles: users, email, apache2, vault, unbound) are done; Terraform for the new instance + 4-volume EBS layout written 2026-07-11, bootstrap (cloud-init admin→`kecsi` rename + EBS mount at first boot, dedicated `linuxbox2026` SSH keypair read from Vault via two split KV entries) implemented 2026-07-12 (`terraform validate` clean); still needed before `terraform apply`: manual `vault kv put` for `ec2/ssh-edge-bootstrap-public`/`-private`; see `docs/howtos/ec2-rebuild-plan.md` and `docs/howtos/ec2-ebs-volumes.md` for full status
- [ ] **Vault ↔ Ansible integration — last verification step** — code + bootstrap done 2026-07-05 (terraform/vault/ applied, all 5 EC2 secret groups migrated into Vault, vault_kv2_get lookups verified working locally); only remaining step is a live `ansible-playbook -i inventory/aws_hosts playbooks/ec2-core.yml --check` against the production EC2 host to confirm end-to-end — deferred since it's the live email server; `secrets.yml`'s original values are untouched as fallback. See `docs/howtos/vault-secrets-architecture.md`.

### Terraform (`terraform/aws/`)

- [x] **Terraform state backend**, **EC2 instance**, **S3 buckets**, **Route53 hosted zone** — all codified as modules (`ec2`, `eip`, `route53`, `s3`) in `terraform/aws/main.tf`

### Ansible — inventory, roles & playbooks

- [ ] **`setup_bichon` role** — deploy Bichon email archive (Rust, IMAP pull from Dovecot, React UI); placeholder role created; see `docs/research/email-archive-software.md` for evaluation
- [ ] **`configure_wireguard` role** — EC2 as Wireguard hub: wg0 interface, IP forwarding, NAT masquerade; workstation + kube nodes as spokes; keypair management; `wg0.conf` via Jinja2 templates; peer list from inventory
- [ ] **`ec2-wireguard.yml` playbook** — deploy Wireguard hub on EC2 and configure spoke peers
- [ ] **`configure_route53` role** — upsert Route53 A/TXT/MX records via `community.aws.route53` (analogous to `configure_mikrotik-router` + `configure_cloudflare-zone`); credentials via `secrets.yml` (`aws_access_key_id`, `aws_secret_access_key`); `configure-route53.yml` playbook
- [x] **AWS inventory group**, **`ec2-core.yml`/`ec2-mail.yml`/`ec2-web.yml`/`ec2-vault.yml` playbooks**, **`setup_email-server` role** — all implemented, see `docs/howtos/ec2-rebuild-plan.md`

## Dotfiles migration (archive `../dotfiles`)

Goal: fold everything still-relevant from the old `../dotfiles` repo into this
repo, move sensitive/work-identifying info into Vault, drop what's dead, then
archive that repo. Full original analysis in `../dotfiles/TODO.md` (kept
there until the repo is archived). **Scope decision (2026-07-11, overrides
the note in `../dotfiles/TODO.md`):** workstation-personal secrets (SSH
client config, PyPI feed) go into the **real HashiCorp Vault**
(`vault.kecskemethy.hu`), not `local.yml` Ansible-Vault — needs a new
workstation/personal KV v2 mount + policy (current `terraform/vault/` scope
is EC2-only) and a scope-note update in `docs/howtos/vault-secrets-architecture.md`.

### Vault-bound (workstation/personal secrets)

- [ ] Add a workstation/personal KV v2 mount + policy to `terraform/vault/` (mirrors the existing `ec2/` mount)
- [ ] **`configure_ssh-client` role (new)** — templates `~/.ssh/config` from a var (e.g. `ssh_client_hosts`) sourced via `vault_kv2_get`, not committed as a static file. Source data is `../dotfiles/.ssh/config`; no private key files are in that repo, only the config referencing them. **Confirmed (2026-07-11):** only `Host linuxbox.hu` (`IdentityFile ~/.ssh/linuxbox2016.pem`) is live — it's the EC2 box — so it's the only entry to actually migrate into Vault/the new role. `gitbud.epam.com`, `ssh.dev.azure.com`, `git.epam.com`, `*.us-west-2.prod.hcom-data-science.aws.hcom`, `10.*`, and `127.0.0.1` (`~/.ssh/zk-bdcc`) are all former-employer and dead, drop them. `Host github.com` currently borrows `git.epam.com`'s key — needs a real personal key when the config is rebuilt (not migrated as-is).
- [x] `.pypirc` (Azure DevOps feed, org `qrdaas`, index-server `data-pkgs`) — confirmed dead (2026-07-11), same former-employer bucket; drop, no migration
- [ ] `bin/vault_login.sh` / `bin/vault_env.sh` → keep, repoint from dev `localhost:443` to `vault.kecskemethy.hu`
- [ ] `bin/vault_approle_token_gen.sh` → adapt as a general local AppRole-login convenience script reusing the pattern already built for EC2 (`terraform/vault/` generates `role_id`/`secret_id`)

### New roles to add

- [ ] **`configure_bash-aliases` role (new)** — `ll`, `l`, `alert`, `kx`, `kn`, `apt-maintenance`, `brew-maintenance`, `ecr-login`, `git-reset-author` from `../dotfiles/.bash_aliases`; check overlap with existing `exa`/`la` and `k=kubectl` aliases first
- [ ] **krew** (kubectl plugin manager) → fold into `setup_kube-extra`
- [ ] `bin/mc-gruvbox-skin-setup.sh` → fold into `personalise.yml`
- [ ] **Windows Terminal config role (new)** — deploy `windows/AppData/...` (`settings.json` + icons) from WSL2 to the Windows host side
- [ ] `.wsl-config` → drop the Dell OpenManage/WSMAN template entirely; capture only the trailing `[wsl2]` `swap=0` setting as a note in a WSL2 setup doc, not a deployed file
- [ ] **WSL2 systemd enablement** — `bin/WSL2_setup_scripts/02-get_systemd_running_WSL2.sh` is a genuine gap: nothing in homelab codifies `/etc/wsl.conf` (`[boot] command = ...systemd...`) or the `wsl2-systemd` sudoers drop-in. Needs a new task/role (e.g. in `local-core.yml`, Linux/WSL2-only) templating `/etc/wsl.conf` and fetching `00-wsl2-systemd.sh` from `diddledani/one-script-wsl2-systemd`. The other 3 scripts in that dir are already superseded: `00-WSL2-install.txt` is manual PowerShell (pre-Ansible, not automatable — keep only as doc reference if at all), `01-install_docker_in_WSL2.sh` → already covered by `setup_apt_repos` (`docker` tag) in `local-core.yml`, `03-install_k3s_wsl2.sh` → already superseded by `setup_k3s` (and was pinned to obsolete k3s v1.22.7/kubectl 1.23.0 anyway)
- [x] **Brewfile gaps** — diffed `brew/Brewfile` + `brew/Brewfile.work` against all brew-based roles (2026-07-11). Already covered: `argocd`/`helm`/`kubernetes-cli` (`setup_kube-extra`), `awscli`/`aws-sam-cli` (`setup_cloud-aws`), `fzf`/`gcc`/`git-delta`/`go-task`/`oh-my-posh`/`pre-commit`/`python@3.12`/`uv`/`yq`/`jq`/`gnupg` (`setup_minimal`), `opentofu`/`terragrunt`/`terrascan`/`tfupdate` (`setup_iac-extra`), `terraform-docs`/`tflint`/`trivy` (`setup_iac-terraform`/`setup_security-tools`). Skipped per decision (2026-07-11): `terraformer`, `tfsec`, `hcledit`. **Added (2026-07-11):** `ffmpeg` → `setup_minimal`; `glab` → inline task in `local-dev.yml` (next to `gh`); `pyenv`/`pyenv-virtualenv`/`python-tk@3.12`/`python-tk@3.13` → `setup_python-uv` (new `pyenv_enabled`/`python_tk_versions` vars); `hadolint` → `setup_security-tools`; `helm-docs` → `setup_kube-extra`; `nvm` → **replaced** the direct `node` brew install in `setup_nodejs-dev-tools` (Node.js now installed/managed via `nvm install`, `pnpm` remains a standalone brew binary), plus a new `upgrade_nodejs` role wired into `upgrade-local.yml` to keep the nvm-managed Node version and global npm packages current. Not worth adding (former-employer/work-specific): `amazon-ecs-cli`, `atlantis`, `container-structure-test`, `dotbot`, `git-remote-codecommit`, `grok`, `infracost`, `jfrog-cli`, `bitbucket-cli` (gildas/tap)

### Confirmed dead — delete from dotfiles, no migration

- [ ] zsh + Powerlevel10k (`.zshrc`, `.p10k.zsh`) — superseded by bash + oh-my-posh
- [ ] Spark/Jupyter (`bin/shutdown_spark.sh`, `bin/startup_spark_and_jupyter.sh`, `.jupyter/jupyter_lab_config.py`, `SPARK_HOME`/`SBT_HOME`/`SONAR_SCANNER_HOME` block in `.bashrc`) — tied to a prior on-prem Spark setup; `jupyter_lab_config.py` is stock boilerplate
- [ ] `bin/adfs.py`, `bin/adfs-p3.py`, `bin/ec2.py` — former-employer AWS ADFS SAML login + EC2 helper; superseded by Terraform + dynamic inventory
- [x] `bin/ssh-agent-start.sh` — loaded `~/.ssh/zk-bdcc.pem`; confirmed dead (2026-07-11) along with the `hcom-data-science`/EPAM `.ssh/config` entries it belongs to
- [x] `bin/crudini.py` — old Python2 boto3 STS AssumeRole helper (misleadingly named after the actual `crudini` INI tool); confirmed dead (2026-07-11), same former-employer AWS access pattern as `adfs.py`/`ec2.py`
- [x] `.condarc` — confirmed dead (2026-07-11), not using conda anymore
- [ ] `bin/vault_aws_aim_key_rotate/` (`rotate_keys.sh`, `rotate_mlflow_iam_key_in_vault.sh`, `iam_output.json`, `new_nomad_iam_key.json`) — references Nomad/MLflow, neither exists in homelab; **check the JSON files for live key material before deleting**
- [ ] Rest of `../dotfiles/TODO.md`'s "Likely dead" list (old Node 15/16/17 apt scripts, `apt-ansible-repo-add-install.sh`, `apt-kubernetes`/`helm`/`hashicorp`/`azure-cli`/`vscode` repo scripts, `apt-liquorix-repo-add.sh`, `apt-overviewer-repo-add.sh`, `apt-jurisic-nextcloud-repo-add.sh`, `.motd_shown`, `.powerline-shell.json`, `LICENSE`) — all already superseded per that repo's analysis, ready to delete

### Already covered — verify then delete from dotfiles

- [ ] `.gitconfig` → `configure_git` role (already a word-for-word superset)
- [ ] oh-my-posh setup → `configure_oh-my-posh` role (homelab has more theme variants already)
- [ ] fzf init → `configure_fzf` role
- [ ] `alias k=kubectl` → already in `setup_kube-extra`
- [ ] VS Code apt/brew install → `setup_vscode` role
- [ ] Terraform/Vault CLI + `VAULT_ADDR` → `setup_iac-terraform` role (note: homelab's `VAULT_ADDR` points at the real `vault.kecskemethy.hu`, don't carry over the old dev value)
- [ ] Azure CLI → `setup_cloud-azure` role
- [ ] `bin/apt-repo-setup-scripts/*` (12 scripts: docker, grafana, gum/charm, mise, firefox/mozilla, sury-php, gitea, duosecurity, twilio, yarn, microsoft, telegraf) → all superseded 1:1 by `setup_apt_repos`
- [ ] `apt-cisofy-repo-add-lynis-install.sh` → `setup_security-tools` role
- [ ] `bin/kubernetes/install-k3s.sh` → `setup_k3s` role; `bin/kubernetes/install-helm.sh` → `setup_kube-extra` (brew-based helm install)
- [ ] `install_oh_my_posh.sh`, `install_delta.sh` → superseded by the relevant Ansible roles above
- [ ] `bin/git-prompt.sh` → redundant, oh-my-posh already renders git status in the prompt

- [x] `.claude/settings.local.json` (in the dotfiles repo itself) — Claude Code local session settings, not real dotfiles content; needs no migration, goes away when the repo is archived

### Execution order

1. **Audit fully resolved (2026-07-11)** — all SSH hosts, `.pypirc`, `crudini.py`, `.condarc`, the Brewfile diff, and the WSL2 scripts have been triaged, see sections above.
2. Stand up the workstation/personal Vault KV mount + `configure_ssh-client` role.
3. Add the other new roles (`configure_bash-aliases`, Windows Terminal, krew, mc-gruvbox, WSL2 systemd enablement) and wire into `local-core.yml`/`personalise.yml`.
4. Decide on the Brewfile gap packages (`ffmpeg`, `gh`, `glab`, `pyenv`, etc.) and add to the appropriate existing roles.
5. Delete superseded/dead files from `../dotfiles` as each piece is confirmed migrated.
6. Once nothing unique remains, archive the `../dotfiles` repo.

## Projects / Repos

- [ ] **homelab-notify** (`forgejo.kecskemethy.org/kecsi/homelab-notify`) — typed ntfy CLI wrapper (Python); CI pipeline is red, needs investigation
- [ ] **homelab-status** (`forgejo.kecskemethy.org/kecsi/homelab-status`) — poll Gatus API, print formatted uptime summary or send ntfy alert on degraded services
- [ ] **forgejo-mirror-sync** (`forgejo.kecskemethy.org/kecsi/forgejo-mirror-sync`) — manage `mirrors` org via Forgejo API: given a list of upstream GitHub repos, create/update mirror repos reproducibly

## Deferred (known blockers)

- [ ] **Headlamp OIDC** — login works but shows no permissions after OIDC sign-in; next debug steps:
  1. Enable kube-apiserver audit logging to confirm authenticated username in token
  2. Add `offline_access` to OIDC_SCOPES in `headlamp-oidc` SealedSecret (re-seal required)
  3. Confirm whether Headlamp `-in-cluster` + OIDC mode substitutes user token for SA token

## Ansible secrets management

- [x] ~~ansible-vault~~ — superseded 2026-07-05: went straight to real HashiCorp Vault integration instead of this stopgap (see "AWS / EC2 & Email" above); `secrets.yml` remains as the fallback/non-EC2 secrets store, not vault-encrypted
- [ ] **HashiCorp Vault ↔ Ansible** — see "Vault ↔ Ansible integration — last verification step" under AWS / EC2 & Email above; endgame once fully cut over: `secrets.yml` contains only non-sensitive infra topology plus the AppRole credentials themselves
- [ ] **Helper scripts (`scripts/`)** — (a) random secret generator: writes `INTERNAL_TOKEN`, `SECRET_KEY`, `client-secret` etc. into `secrets.yml`; (b) ✅ `scripts/cloudflare-zone-id.sh <token> [domain]` — looks up zone ID and prints `secrets.yml` snippet; auto-reads `domain_name` from `vars.yml` if domain omitted

## AWS / Golden Image

- [ ] **Packer golden AMI** — bake a Debian 13 base image with security hardening and base packages pre-installed; faster EC2 cold-start than provisioning from scratch; build pipeline in a dedicated Forgejo repo with CI pushing finished AMI to ECR; replace `data "aws_ami" "debian13"` in Terraform once pipeline is stable

## Big migrations

- [ ] **Vault (Kubernetes side)** — replace SealedSecrets with HashiCorp Vault (or OpenBao) for secrets management; separate, bigger lift than the EC2/Ansible Vault integration above — needs External Secrets Operator or Vault Agent Injector to actually deliver secrets into pods; 49 SealedSecrets currently exist across `kube-gitops/`; significant migration: re-seal all secrets, update ArgoCD apps, update workflows
- [ ] **Cloudflare → Route53 + Wireguard** — long-term full replacement of Cloudflare as DNS provider and remote-access tunnel; stages: (1) Route53 becomes authoritative DNS (migrate all records, update registrar NS); (2) cert-manager DNS01 ClusterIssuer switches to Route53 provider (replaces Cloudflare API token); (3) Wireguard hub-and-spoke (EC2 gateway) replaces Cloudflare WARP for remote cluster access; (4) decommission `configure_cloudflare-zone` role and cloudflared tunnel; blocked on: Route53 zone live, Wireguard stable

## Low priority / Future

- [ ] **LVM / base OS provisioning not codified** — kube node disk layout (VG/LV partitioning: root, var, home, tmp, swap, backup) was set up manually at OS install time, before any Ansible role touches the box; nothing in this repo reproduces it. Surfaced 2026-07-05 when `var` was manually extended via `lvextend`+`resize2fs` on all 4 kube nodes (+35G on hppd600g6, +10G on the other three, to grow Longhorn's usable capacity) — a rebuilt node today would come up with the original LV sizes, not these. Needs either an Ansible role (`community.general.lvg`/`lvol` modules) run during initial provisioning, or at minimum a doc capturing the intended per-node LV layout so a rebuild can replicate it by hand.

- [ ] **Justfile** — create and maintain a repo-level `justfile` as the single entry point for all common commands (Ansible playbooks, Terraform ops, kubectl one-liners, cluster rebuild runbook); replaces scattered README snippets; `just` is already installed via `setup_minimal` brew packages

- [ ] **Wiki.js VolSync backup** — add daily restic backup for wiki.js PVC (same pattern as ntfy/gatus/mealie); Outline replaced by Wiki.js
- [ ] **Kustomize domain injection** — eliminate hardcoded `kecskemethy.org` and `192.168.1.101` from `kube-gitops/` manifests (IngressRoutes, certificates, deployments, Traefik values annotation); use Kustomize replacements or a common vars ConfigMap
- [ ] **ArgoCD app repo URLs** — 40+ `repoURL: https://github.com/kecsi-san/homelab.git` hardcoded in ArgoCD app files (both k8s and k3s); parameterise so the repo is forkable without find-replace; options: Kustomize variable, or a bootstrap ConfigMap read by the root app
- [ ] **macOS k3s port mapping** — k3d cluster missing `--port "80:80@loadbalancer" --port "443:443@loadbalancer"` flags
- [ ] **macOS playbook review** — many roles behave differently on Darwin; consider a dedicated `local-mac.yml`

## Done

- [x] **ArgoCD RBAC — switch to group-based** — `homelab-admins` Authentik group + Groups scope mapping via `aaa-groups.yaml` blueprint; ArgoCD provider gets groups claim; `argocd-rbac-cm.yaml` uses `g, homelab-admins, role:admin`
- [x] **Forgejo SSH (port 22)** — Traefik TCP entrypoint (`ssh`, container 2022 → LB port 22); IngressRouteTCP with HostSNI(*); clone URL: `git@forgejo.kecskemethy.org:user/repo.git`
- [x] **Authentik on k3s** — deployed and synced; Forgejo OAuth2 login verified working
- [x] **ArgoCD Authentik OIDC on k3s** — verified working; `homelab-admins → role:admin`; fix: `app.kubernetes.io/part-of: argocd` label required on oidc secret
- [x] **Wiki.js on k3s** — verified working; Authentik OIDC login confirmed; admin group; UUID tightened to strict in blueprint
- [x] **Forgejo Actions runner on k3s** — verified working; `k3s-runner` picked up push job, ran in `node:20-bookworm` via DinD
- [x] **Cloudflare ECH → Ansible** — `configure_cloudflare-zone` role + `configure-cloudflare.yml` playbook; idempotent GET+PATCH; credentials via `secrets.yml` (`cloudflare_api_token`, `cloudflare_zone_id`)
- [x] **Monitoring stack — seal OAuth2 secret** — sealed for both namespaces; Grafana OAuth2 login verified working
- [x] **Monitoring stack — AlertManager → ntfy** — custom Python webhook bridge in ntfy namespace; token sealed; AlertManager default receiver = ntfy; Watchdog + InfoInhibitor silenced via null route
- [x] **Monitoring stack — additional dashboards** — Node summary (11074), Longhorn (13032), Traefik (17347), ArgoCD (14584); ServiceMonitors enabled for Traefik/ArgoCD/Longhorn; KPS discovers all namespaces
- [x] **Monitoring stack (kube-prometheus-stack)** — fully synced and healthy: KPS v86.1.0 + grafana-operator v5.23.0 + Grafana (Authentik OAuth2 login verified); Longhorn PVC 50Gi Prometheus + 5Gi AlertManager; static scrapes for 4-node Debian node_exporter; 3 dashboards; Grafana at grafana.kecskemethy.org
- [x] ArgoCD Authentik OIDC on k3s — verified (2026-06-03); gotcha: oidc secret needs `app.kubernetes.io/part-of: argocd` label
- [x] Wiki.js on k3s — deployed + OIDC verified (2026-06-03); gotcha: CNPG managed role secret needs `username` key for new roles
- [x] Forgejo Actions runner on k3s — verified working (2026-06-03)
- [x] Authentik upgraded to 2026.5.0 on k8s; DB migration clean; OIDC providers verified working
- [x] Traefik upgraded to v40 (chart 40.2.0 / Traefik 3.7.1) on both k8s and k3s; fixed breaking `ports.web.http.redirections` rename
- [x] sealed-secrets upgraded to 2.18.6 on both clusters
- [x] README updated: new title, platform stack table, repo description and topics refreshed
- [x] ArgoCD RBAC group-based verified: login via Authentik → homelab-admins group → role:admin
- [x] ArgoCD Kubernetes 1.35 compat: `knownTypeFields` for `terminatingReplicas` on all workload types; `ignoreDifferences` for Prometheus/Alertmanager new spec fields (`hostNetwork`, `tsdb`, `otlp*`)
- [x] Authentik 2026.5.0 `grant_types` change: new OAuth2 providers default to empty; must set `authorization_code`+`refresh_token` explicitly in blueprints
- [x] ArgoCD Authentik OIDC sign-in + RBAC (initial email-based setup)
- [x] Backstage custom image built via Forgejo Actions CI, pushed to Forgejo OCI registry
- [x] Backstage Authentik OIDC sign-in (ApiBlueprint + SignInPageBlueprint in new declarative frontend)
- [x] Backstage root `/` → `/catalog` redirect
- [x] Homepage: removed broken Kubernetes metrics widget, fixed Backstage icon (`si-backstage`)
- [x] Glance: renamed main page to `Homelab` (browser tab title)
- [x] Forgejo runner: fixed Docker connectivity (DinD via TCP `localhost:2375`), fixed RWO PVC deadlock (`Recreate` strategy)
- [x] Mealie: verified working on both LAN and WARP
- [x] Authentik 2026.2.3 deployed; Forgejo + Outline + Longhorn + Traefik integrated
- [x] Cloudflare ECH disabled (zone-wide, API only — no Free plan UI toggle)
- [x] MikroTik AAAA wildcard overrides (`::1`) to fix Happy Eyeballs / QUIC failures on LAN
