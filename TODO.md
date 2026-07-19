# TODO

Planned work, known issues, and ideas. Check here before starting a new session.

## Active / Next up

- [ ] **Helm 4 migration** — workstation `helm` was unpinned and silently drifted to v4.2.3 via `brew upgrade` (`upgrade-local.yml`); pinned back to `helm@3` (3.21.3) in `roles/setup_kube-extra/tasks/main.yml` on 2026-07-19 to unblock `post-k3s.yml`. Root cause of the break: Helm 4 enforces strict Kubernetes Server-Side-Apply field-manager ownership instead of Helm 3's lenient 3-way merge — `argocd-cm`/`argocd-rbac-cm` are co-managed by the ArgoCD Helm chart *and* ArgoCD's own self-referential `argocd-config` GitOps Application (writes `oidc.config`/`url`/`policy.csv`), and Helm 4 refuses the overlap. Before ever re-attempting Helm 4: (1) fix the ArgoCD chart values so it stops templating those specific ConfigMap keys, leaving `argocd-config` as sole owner, (2) audit `setup_traefik`/`setup_sealed-secrets`/`setup_headlamp`/`setup_longhorn` for the same class of dual-ownership conflict before their next Helm upgrade — none hit it yet, but all use the same `kubernetes.core.helm` + separate-raw-manifest pattern that caused this. Kubespray's own Helm on the kube nodes (`/usr/local/bin/helm`, v3.18.4) is unaffected — separate install mechanism, already pinned by Kubespray's release branch.
- [ ] **Backstage Kubernetes plugin** — shows "Entity context is not available" as a standalone nav item; either configure it for catalog entities (requires annotations) or remove `kubernetesPlugin` from `App.tsx`
- [ ] **VictoriaLogs** — log aggregation (no log storage currently); single-binary replacement for Loki, significantly lower RAM, simpler to operate; community is moving away from Loki toward VictoriaLogs; deploy alongside kube-prometheus-stack; Fluent Bit or Grafana Alloy as log forwarder
- [ ] **ArgoCD v3 upgrade prep** — target chart `10.1.4` (ArgoCD v3.4.5) vs current `7.7.5` (v2.14.5 k8s / v2.13.1 k3s, already drifted from each other — sync via `post-k3s.yml`/`post-k8s.yml` first). Checked this repo's config against the official 2.14→3.0 upgrade notes: not affected by the Dex RBAC change (uses Authentik OIDC), the ApplicationSet nested-selector change (no ApplicationSets in use), the legacy argocd-cm repo config removal (repos are per-Application `repoURL`), or the logs-RBAC-enforcement change (`policy.default: role:readonly` already set on both clusters — explicitly exempts it per the upgrade doc). Two things to actually check before upgrading: (1) any `null` values in the Helm values files ArgoCD renders for its Helm-sourced Applications — Helm 3.17.1 (bundled in the 3.0 chart) changed `null`-handling behavior; (2) do a full `argocd app sync` across all Applications right after upgrading to avoid the label→annotation resource-tracking edge case (orphaned resources if a sync that deletes something happens before the first post-upgrade sync)

<details>
<summary>Recently completed</summary>

- [x] **Cilium Hubble UI** — exposed at https://hubble.kecskemethy.org (2026-07-19); was already running (Kubespray's `cilium_enable_hubble`/`cilium_hubble_install`/`cilium_hubble_relay` already true), just needed IngressRoute + Certificate + Homepage tile, same pattern as every other internal tool
- [x] **Kromgo** — badges live on GitHub README; 12 metrics: versions, nodes, pods, failed pods, CPU, memory, Longhorn storage, birth age, uptime age, alerts, ArgoCD out-of-sync
- [x] **TargetDown alert** — investigated (2026-07-19), not an ongoing issue: 0 down targets currently, only `pending` blips found in the last 24h (kube-controller-manager/kube-scheduler in kube-system), timestamps line up exactly with today's `upgrade_cluster_setup=true` rolling control-plane restart — self-resolved well before the alert's 10-minute sustained threshold, never reached `firing`. Rule (`kube-prometheus-stack-general.rules`) is a generic `>10% targets down for 10m` heuristic, expected to blip briefly during any rolling restart
- [x] **`kube_controller_terminated_pod_gc_threshold: 20`** — confirmed live on all 3 control-plane nodes (2026-07-19); required `ansible-playbook -b -e upgrade_cluster_setup=true playbooks/k8s.yml` — this specific class of kubeadm-managed control-plane arg (apiserver/controller-manager/scheduler) only pushes to the live `kubeadm-config` ConfigMap + regenerates static pod manifests when `upgrade_cluster_setup: true` is explicitly passed (defaults `false` in Kubespray as a safety guard); a plain `k8s.yml` rerun silently leaves the on-disk kubeadm-config updated but the live cluster untouched — worth remembering for any future kube-apiserver/controller-manager/scheduler extra_args change
- [x] **Graceful Node Shutdown** — confirmed live on all 4 nodes (2026-07-19), `shutdownGracePeriod: 120s` / `shutdownGracePeriodCriticalPods: 30s` in `/etc/kubernetes/kubelet-config.yaml` (not `/var/lib/kubelet/config.yaml` — that path is a stale unused leftover, don't check it for kubelet config verification). Unlike the GC threshold above, kubelet config applies unconditionally every `k8s.yml` run, no `upgrade_cluster_setup` needed
- [x] **`setup_argocd-apps` ClusterIssuer task vs git-tracked manifest** — `roles/setup_argocd-apps/templates/cluster-issuer.yaml.j2` applies `ClusterIssuer/letsencrypt-prod` via raw `kubectl apply` on every `post-k3s.yml`/`post-k8s.yml` run, *before* the ArgoCD root Application (which is what installs cert-manager's CRDs via GitOps) — this is how both clusters' issuers originally got created outside git/ArgoCD tracking, and why k3s's silently vanished for months (fixed 2026-07-19, both clusters now also have `kube-gitops/{k3s,k8s}/cert-manager/clusterissuer.yaml` tracked via ArgoCD `selfHeal: true`). **Decided to leave the Ansible task as-is**: content matches the git-tracked manifest exactly (same `acme_email` from `secrets.yml`) so the redundancy is harmless, and removing it risks breaking a from-scratch bootstrap (no dedicated cert-manager role exists — this task running *before* the CRDs are installed may be an intentional fail-and-retry-on-rerun step). Just something to know about if the two ever get edited independently and drift.
- [x] **PR #37 `chore(helm): Update helm charts`** — merged (2026-07-19); 6 Helm chart bumps across k3s+k8s (authentik, cert-manager, cnpg, reloader, sealed-secrets, traefik, kube-prometheus-stack), all patch/minor, no majors

</details>

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

- [x] Add a workstation/personal KV v2 mount + policy to `terraform/vault/` (mirrors the existing `ec2/` mount) — done 2026-07-19, `vault_mount.workstation` + `vault_policy.workstation_admin`
- [x] **`configure_ssh-client` role** — done 2026-07-19, templates `~/.ssh/config` from Vault, verified end-to-end (real SSH connection succeeded using the rendered config/keys). Scope grew beyond the original single-host plan once the live config was actually checked — see `roles/configure_ssh-client/README.md` for the final three-path Vault design (per-machine config list + generic key pool + host-scoped key pool, so `id_ed25519`-style default filenames don't collide across machines). Migrated: `linuxbox2026` (current EC2 box; `linuxbox2016.pem` kept archived in Vault but not wired into any active config — superseded, not deleted), `aws-tefl-2016` (`*.tefl.com`), `git-epam-com` (kept deliberately for `gitlab.com`; dropped `github.com`'s borrowed use of it per the original 2026-07-11 audit note — needs a real personal key before re-adding), `id_ed25519` (kube nodes, host-scoped to avoid cross-machine collision)
- [ ] **`github.com` real personal key** — generate a new key not borrowed from the dead `git.epam.com.pem`, then add a `workstation/ssh-config/penguinaid` entry for it (`key_scope: generic` if it'll also be used from other machines, e.g. the macOS laptop)
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

### Execution order

1. **Audit fully resolved (2026-07-11)** — all SSH hosts, `.pypirc`, `crudini.py`, `.condarc`, the Brewfile diff, and the WSL2 scripts have been triaged; dead/already-covered items tracked in `../dotfiles/TODO.md` itself (no action needed in this repo — see scope decision below).
2. ~~Stand up the workstation/personal Vault KV mount + `configure_ssh-client` role.~~ Done 2026-07-19.
3. Add the other new roles (`configure_bash-aliases`, Windows Terminal, krew, mc-gruvbox, WSL2 systemd enablement) and wire into `local-core.yml`/`personalise.yml`.
4. Decide on the Brewfile gap packages (`ffmpeg`, `gh`, `glab`, `pyenv`, etc.) and add to the appropriate existing roles.
5. Once steps 2–4 are done, archive `../dotfiles` as-is (2026-07-19 scope decision: no per-file deletion cleanup in that repo first — it's about to be archived and read-only, not worth the churn; the dead/superseded items are already recorded in its own `TODO.md`)

## Projects / Repos

- [ ] **homelab-notify** (`forgejo.kecskemethy.org/kecsi/homelab-notify`) — typed ntfy CLI wrapper (Python); CI pipeline is red, needs investigation
- [ ] **homelab-status** (`forgejo.kecskemethy.org/kecsi/homelab-status`) — poll Gatus API, print formatted uptime summary or send ntfy alert on degraded services
- [ ] **forgejo-mirror-sync** (`forgejo.kecskemethy.org/kecsi/forgejo-mirror-sync`) — manage `mirrors` org via Forgejo API: given a list of upstream GitHub repos, create/update mirror repos reproducibly

## Deferred (known blockers)

- [ ] **Hubble UI Authentik SSO** — tried 2026-07-19, reverted, LAN-only again. Hubble's frontend makes background `fetch()` calls for its streaming API (`/api/control-stream`, `/api/service-map-stream`); when ForwardAuth returns a `302` for those calls, `fetch()` tries to auto-follow it cross-origin to `authentik.kecskemethy.org`, which requires CORS that Authentik's `/application/o/authorize/` endpoint doesn't provide (built for top-level navigation, not XHR/fetch) — browser blocks it, Hubble shows "Data streams are reconnecting..." forever. Main page loads fine, no actual functionality works. Longhorn doesn't hit this (no comparable background streaming calls) despite using the identical `authentik-forwardauth` middleware. Would need either a fix on Hubble UI's side (session/credentials handling for its fetch calls) or a different auth approach before retrying — not investigated further.
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
