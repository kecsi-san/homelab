# TODO

Planned work, known issues, and ideas. Check here before starting a new session.

## Active / Next up

- [ ] **Backstage Kubernetes plugin** — shows "Entity context is not available" as a standalone nav item; either configure it for catalog entities (requires annotations) or remove `kubernetesPlugin` from `App.tsx`
- [x] **Kromgo** — badges live on GitHub README; 12 metrics: versions, nodes, pods, failed pods, CPU, memory, Longhorn storage, birth age, uptime age, alerts, ArgoCD out-of-sync
- [ ] **VictoriaLogs** — log aggregation (no log storage currently); single-binary replacement for Loki, significantly lower RAM, simpler to operate; community is moving away from Loki toward VictoriaLogs; deploy alongside kube-prometheus-stack; Fluent Bit or Grafana Alloy as log forwarder
- [ ] **TargetDown alert** — investigate what Prometheus target is actually down (wasn't confirmed firing yet)
- [ ] **`kube_controller_terminated_pod_gc_threshold: 20`** — set in `inventory/group_vars/k8s_cluster/k8s-cluster.yml` but needs `ansible-playbook -b playbooks/k8s.yml` rerun to actually take effect on kube-controller-manager

## Periodic checks

Recurring maintenance — not one-off tasks; re-verify occasionally rather than checking off.

- **Kubernetes cluster upgrade** — Kubespray pinned to `release-2.31` in `requirements.yml`, running Kubernetes v1.35.4 on all 4 nodes (checked 2026-07-05). Check https://github.com/kubernetes-sigs/kubespray/releases for newer release branches supporting a newer Kubernetes minor version; rerun `ansible-galaxy install -r requirements.yml -f` then `ansible-playbook -b playbooks/k8s.yml` to upgrade. Not Renovate-tracked (git dependency in `requirements.yml`, not a package manager Renovate understands here).

- **ArgoCD version** — `argocd_chart_version` in `roles/setup_argocd/defaults/main.yml` is a plain Ansible default, not tracked by Renovate; the two clusters only upgrade when someone reruns `post-k8s.yml`/`post-k3s.yml` after bumping it, so they can silently drift apart. Check https://github.com/argoproj/argo-helm for newer releases and confirm both clusters still match. Last checked 2026-07-05: k8s v2.14.5 (chart 7.7.5), k3s v2.13.1 (older chart pin — reran less recently).

## AWS / EC2 & Email

- [ ] **EC2 rebuild — Phase 6** — new instance provisioning + data migration + EIP cutover + old-instance decommission; Phases 1–5 (all Ansible roles: users, email, apache2, vault, unbound) are done; see `docs/howtos/ec2-rebuild-plan.md` for the full phased plan and current status
- [ ] **Vault ↔ Ansible integration** — architecture designed, not yet built; see `docs/howtos/vault-secrets-architecture.md` and "Ansible secrets management" below

### Terraform (`terraform/aws/`)

- [x] **Terraform state backend**, **EC2 instance**, **S3 buckets**, **Route53 hosted zone** — all codified as modules (`ec2`, `eip`, `route53`, `s3`) in `terraform/aws/main.tf`

### Ansible — inventory, roles & playbooks

- [ ] **`setup_bichon` role** — deploy Bichon email archive (Rust, IMAP pull from Dovecot, React UI); placeholder role created; see `docs/research/email-archive-software.md` for evaluation
- [ ] **`configure_wireguard` role** — EC2 as Wireguard hub: wg0 interface, IP forwarding, NAT masquerade; workstation + kube nodes as spokes; keypair management; `wg0.conf` via Jinja2 templates; peer list from inventory
- [ ] **`ec2-wireguard.yml` playbook** — deploy Wireguard hub on EC2 and configure spoke peers
- [ ] **`configure_route53` role** — upsert Route53 A/TXT/MX records via `community.aws.route53` (analogous to `configure_mikrotik-router` + `configure_cloudflare-zone`); credentials via `secrets.yml` (`aws_access_key_id`, `aws_secret_access_key`); `configure-route53.yml` playbook
- [x] **AWS inventory group**, **`ec2-core.yml`/`ec2-mail.yml`/`ec2-web.yml`/`ec2-vault.yml` playbooks**, **`setup_email-server` role** — all implemented, see `docs/howtos/ec2-rebuild-plan.md`

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

- [ ] **ansible-vault** — encrypt `secrets.yml` with ansible-vault and commit it; store vault password in `~/.vault-pass` (gitignored); add `--vault-password-file ~/.vault-pass` to playbook docs; short-term fix until HashiCorp Vault is deployed
- [ ] **HashiCorp Vault ↔ Ansible** — replace `secrets.yml` values with `community.hashi_vault` lookups so Ansible fetches secrets at runtime; blocked on Vault deployment (see Big migrations below); endgame: `secrets.yml` contains only non-sensitive infra topology
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
