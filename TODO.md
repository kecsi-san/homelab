# TODO

Planned work, known issues, and ideas. Check here before starting a new session.

## Active / Next up

- [x] **Forgejo SSH (port 22)** — Traefik TCP entrypoint (`ssh`, container 2022 → LB port 22); IngressRouteTCP with HostSNI(*); clone URL: `git@forgejo.kecskemethy.org:user/repo.git`
- [ ] **Authentik on k3s** — k3s has no SSO yet; mirror k8s stack (2026.5.0 + blueprints + PostSync job)
- [x] **Cloudflare ECH → Ansible** — `configure_cloudflare-zone` role + `configure-cloudflare.yml` playbook; idempotent GET+PATCH; credentials via `secrets.yml` (`cloudflare_api_token`, `cloudflare_zone_id`)
- [ ] **Backstage Kubernetes plugin** — shows "Entity context is not available" as a standalone nav item; either configure it for catalog entities (requires annotations) or remove `kubernetesPlugin` from `App.tsx`
- [ ] **Monitoring stack (kube-prometheus-stack)** — Prometheus + Grafana + AlertManager + node-exporter + kube-state-metrics via `prometheus-community/kube-prometheus-stack` Helm chart; k8s cluster only; Longhorn PVC for Prometheus storage (15-day retention default); AlertManager → ntfy webhook for alerts; Authentik forwardAuth on Grafana IngressRoute; Grafana dashboards: node overview, Longhorn, Traefik, ArgoCD. Note: VictoriaMetrics is a leaner alternative if memory becomes a concern; Garage (already deployed) is ready as a Thanos/VictoriaMetrics remote-write target if long-term retention is needed later.
- [ ] **Kromgo** — expose named Prometheus queries as HTTP endpoints for Homepage dashboard widgets (replaces broken Kubernetes metrics widget removed earlier); requires monitoring stack above; configure `config.yaml` with cluster CPU%, RAM%, pod count, node count
- [ ] **grafana-operator** — replace KPS-bundled Grafana with grafana-operator for declarative `GrafanaDashboard` / `GrafanaDatasource` CRDs in Git; community standard in most-followed homelab repos (onedr0p, bjw-s, joryirving); adopt from the start to avoid migrating later; depends on monitoring stack above
- [ ] **VictoriaLogs** — log aggregation (no log storage currently); single-binary replacement for Loki, significantly lower RAM, simpler to operate; community is moving away from Loki toward VictoriaLogs; deploy alongside kube-prometheus-stack; Fluent Bit or Grafana Alloy as log forwarder

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
- [ ] **Helper scripts (`scripts/`)** — (a) random secret generator: writes `INTERNAL_TOKEN`, `SECRET_KEY`, `client-secret` etc. into `secrets.yml`; (b) Cloudflare zone ID lookup: `GET /zones?name=<domain>` → prints zone ID for `secrets.yml`; useful when bootstrapping on a new machine

## Big migrations

- [ ] **Vault** — replace SealedSecrets with HashiCorp Vault (or OpenBao) for secrets management; significant migration: re-seal all secrets, update ArgoCD apps, update workflows

## Low priority / Future

- [ ] **Outline VolSync backup** — add daily restic backup for `outline-data` PVC (same pattern as ntfy/gatus/mealie)
- [ ] **Kustomize domain injection** — eliminate hardcoded `kecskemethy.org` and `192.168.1.101` from `kube-gitops/` manifests (IngressRoutes, certificates, deployments, Traefik values annotation); use Kustomize replacements or a common vars ConfigMap
- [x] **ArgoCD RBAC — switch to group-based** — `homelab-admins` Authentik group + Groups scope mapping via `aaa-groups.yaml` blueprint; ArgoCD provider gets groups claim; `argocd-rbac-cm.yaml` uses `g, homelab-admins, role:admin`
- [ ] **ArgoCD app repo URLs** — 40+ `repoURL: https://github.com/kecsi-san/homelab.git` hardcoded in ArgoCD app files (both k8s and k3s); parameterise so the repo is forkable without find-replace; options: Kustomize variable, or a bootstrap ConfigMap read by the root app
- [ ] **macOS k3s port mapping** — k3d cluster missing `--port "80:80@loadbalancer" --port "443:443@loadbalancer"` flags
- [ ] **macOS playbook review** — many roles behave differently on Darwin; consider a dedicated `local-mac.yml`

## Done (recent)

- [x] Authentik upgraded to 2026.5.0 on k8s; DB migration clean; OIDC providers verified working
- [x] Traefik upgraded to v40 (chart 40.2.0 / Traefik 3.7.1) on both k8s and k3s; fixed breaking `ports.web.http.redirections` rename
- [x] sealed-secrets upgraded to 2.18.6 on both clusters
- [x] README updated: new title, platform stack table, repo description and topics refreshed
- [x] ArgoCD Authentik OIDC sign-in + RBAC (`zoltan@kecskemethy.hu` → role:admin; default readonly)
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
</content>
