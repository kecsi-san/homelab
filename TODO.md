# TODO

Planned work, known issues, and ideas. Check here before starting a new session.

## Active / Next up

- [ ] **Forgejo SSH (port 22)** — all remotes still HTTPS; expose SSH via Traefik TCP entrypoint or NodePort
- [ ] **Authentik on k3s** — k3s has no SSO yet; mirror k8s stack (2026.2.3 + blueprints + PostSync job)
- [ ] **Cloudflare ECH → Ansible** — ECH was disabled manually via API (`PATCH /zones/{id}/settings/ech`); add to Cloudflare playbook so a zone rebuild doesn't silently break LAN browsing
- [ ] **Backstage Kubernetes plugin** — shows "Entity context is not available" as a standalone nav item; either configure it for catalog entities (requires annotations) or remove `kubernetesPlugin` from `App.tsx`
- [ ] **Monitoring stack (kube-prometheus-stack)** — Prometheus + Grafana + AlertManager + node-exporter + kube-state-metrics via `prometheus-community/kube-prometheus-stack` Helm chart; k8s cluster only; Longhorn PVC for Prometheus storage (15-day retention default); AlertManager → ntfy webhook for alerts; Authentik forwardAuth on Grafana IngressRoute; Grafana dashboards: node overview, Longhorn, Traefik, ArgoCD. Note: VictoriaMetrics is a leaner alternative if memory becomes a concern; Garage (already deployed) is ready as a Thanos/VictoriaMetrics remote-write target if long-term retention is needed later.
- [ ] **Kromgo** — expose named Prometheus queries as HTTP endpoints for Homepage dashboard widgets (replaces broken Kubernetes metrics widget removed earlier); requires monitoring stack above; configure `config.yaml` with cluster CPU%, RAM%, pod count, node count

## Projects / Repos

- [ ] **homelab-notify** (`forgejo.kecskemethy.org/kecsi/homelab-notify`) — typed ntfy CLI wrapper (Python); CI pipeline is red, needs investigation
- [ ] **homelab-status** (`forgejo.kecskemethy.org/kecsi/homelab-status`) — poll Gatus API, print formatted uptime summary or send ntfy alert on degraded services
- [ ] **forgejo-mirror-sync** (`forgejo.kecskemethy.org/kecsi/forgejo-mirror-sync`) — manage `mirrors` org via Forgejo API: given a list of upstream GitHub repos, create/update mirror repos reproducibly

## Deferred (known blockers)

- [ ] **Headlamp OIDC** — login works but shows no permissions after OIDC sign-in; next debug steps:
  1. Enable kube-apiserver audit logging to confirm authenticated username in token
  2. Add `offline_access` to OIDC_SCOPES in `headlamp-oidc` SealedSecret (re-seal required)
  3. Confirm whether Headlamp `-in-cluster` + OIDC mode substitutes user token for SA token

## Big migrations

- [ ] **Vault** — replace SealedSecrets with HashiCorp Vault (or OpenBao) for secrets management; significant migration: re-seal all secrets, update ArgoCD apps, update workflows

## Low priority / Future

- [ ] **Outline VolSync backup** — add daily restic backup for `outline-data` PVC (same pattern as ntfy/gatus/mealie)
- [ ] **Kustomize domain injection** — eliminate hardcoded `kecskemethy.org` from `kube-gitops/` manifests
- [ ] **macOS k3s port mapping** — k3d cluster missing `--port "80:80@loadbalancer" --port "443:443@loadbalancer"` flags
- [ ] **macOS playbook review** — many roles behave differently on Darwin; consider a dedicated `local-mac.yml`

## Done (recent)

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
