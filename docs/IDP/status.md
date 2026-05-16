# IDP Status

## Decision

Deploy a minimal IDP to **k3s** and the same minimal IDP **plus Backstage** to **k8s**.

---

## Component Plan

### Minimal IDP — both clusters (k3s + k8s)

| Component | Tool | Layer | k8s | k3s |
|---|---|---|---|---|
| Shared database | CloudNativePG | Infrastructure | ✅ Done | ✅ Done |
| Git server + OCI registry + CI | Forgejo | Platform | ✅ Done | ✅ Done |
| SSO / Identity Provider | Authentik | Platform | ✅ Done | Planned |
| CI runners | Forgejo Actions | Platform | Planned | Planned |
| Documentation / wiki | Docmost | Platform | Planned | Planned |
| Code analysis (SAST) | Semgrep OSS (CI step) | Quality | Planned | Planned |
| Vulnerability scanning | Trivy (CI step) | Quality | Planned | Planned |

### k8s only — additions on top of minimal

| Component | Tool | Layer | Status |
|---|---|---|---|
| Service catalog | Backstage | Platform | Planned |

---

## Deployment Targets

| Cluster | Scope | Notes |
|---|---|---|
| k3s (WSL2, 1 node, ~12 GB free) | Minimal IDP | Development / experimentation instance |
| k8s (4 nodes, ~84 GB free) | Minimal IDP + Backstage | Production homelab instance |

---

## Build Order

Both clusters follow the same sequence for the minimal IDP:

1. **CloudNativePG** — shared PostgreSQL cluster; everything stateful depends on it
2. **Forgejo** — git + OCI registry + Actions runner; foundations for all pipelines
3. **Authentik** — SSO; wire Forgejo OIDC on install; gates all subsequent UIs
4. **Docmost** — wiki; shares PostgreSQL with Authentik, gains OIDC from Authentik
5. **Semgrep + Trivy** — add as Forgejo Actions pipeline steps; zero new services

k8s only — after minimal IDP is stable:

6. **Backstage** — service catalog; PostgreSQL shared with step 1

---

## Achievements Log

### 2026-05-15 — k8s Authentik deployed and integrated

- **Authentik 2026.2.3** deployed on k8s with standalone `redis:7-alpine`
  (Bitnami images removed from Docker Hub; official redis image used instead)
- **CNPG managed role** for `authentik` user + `Database` CR for `authentik` DB
- **Blueprint** (`kube-gitops/k8s/authentik/configmap-blueprints.yaml`) creates Forgejo
  OAuth2 provider + application in Authentik automatically on worker startup
  - Required `invalidation_flow` field (added in Authentik 2026.x)
- **PostSync job** (`kube-gitops/k8s/forgejo/job-register-authentik.yaml`) registers
  the Authentik auth source in Forgejo's DB after each ArgoCD sync; idempotent
  - Writes minimal `app.ini` to `/var/lib/gitea/custom/conf/` (image GITEA_CUSTOM default)
- **Forgejo `kecsi` admin** account linked to Authentik `kecsi` user via OAuth2
  (`sub_mode: user_username` — Authentik username maps to Forgejo username on first login)
- **User management runbook** at `docs/IDP/user-management.md`

### 2026-05-16 — Authentik forwardAuth + Headlamp OIDC (k8s)

- **Longhorn UI** protected with Authentik `forwardAuth` middleware
  - Proxy provider + application added to blueprint (`longhorn.yaml`)
  - `zzz-outpost.yaml` blueprint assigns provider to the embedded outpost
  - Traefik IngressRoute references `authentik-forward-auth` middleware
- **Headlamp OIDC provider** configured in blueprint (`headlamp.yaml`)
  - `sub_mode: user_username`, `issuer_mode: per_provider`
  - kube-apiserver OIDC flags aligned: `--oidc-issuer-url`, `--oidc-client-id=headlamp`,
    `--oidc-username-claim=preferred_username`
  - ClusterRoleBinding (`headlamp-oidc-kecsi`) grants `cluster-admin` to OIDC user `kecsi`
  - Token lifetimes extended: `access_token_validity: hours=24`, `refresh_token_validity: days=30`
    (default 60 min caused silent session expiry with no refresh token)
  - **⚠ TODO**: Headlamp shows "no permissions" for all resources after OIDC login —
    root cause unresolved (token forwarding to kube-apiserver not confirmed); debug deferred
- **Traefik dashboard** protected with Authentik `forwardAuth` middleware
  - Proxy provider + application added to blueprint (`traefik-dashboard.yaml`)

### 2026-05-16 — Forgejo fixes

- **`Recreate` rollout strategy** added to Forgejo deployment — LevelDB queue at
  `/var/lib/gitea/queues/common` can only be locked by one process; `RollingUpdate`
  caused `CrashLoopBackOff` in the new pod during rollout
- **`ENABLE_REMEMBER_ME=false`** — browser `fetch()` does not flush `Set-Cookie`
  headers before navigation fires; long-term `gitea_incredible` token survived sign-out
  and silently recreated the session

### 2026-05-15 — NTP / chrony

- **`configure_ntp` Ansible role** replaced ntpd with chrony (Debian 13 dropped the
  `ntp` package); MikroTik router as primary NTP, pool.ntp.org as fallback
- Wired into `k8s-nodes.yml` (tag: `ntp`) and `local-core.yml` (Linux only)

---

## Deferred / TODO

### Headlamp OIDC permissions (k8s)

All config verified correct — kube-apiserver flags, Authentik provider, ClusterRoleBinding —
but Headlamp shows "no permissions" after OIDC login. Likely Headlamp is not forwarding the
OIDC ID token to kube-apiserver (falling through to anonymous).

Next debug steps when revisiting:
1. Enable kube-apiserver audit logging to confirm what username the apiserver sees for
   Headlamp's requests
2. Add `offline_access` to `OIDC_SCOPES` in `headlamp-oidc` SealedSecret (re-seal required)
   to enable refresh token flow
3. Check whether Headlamp `-in-cluster` + OIDC mode correctly substitutes the user token
   instead of the in-cluster SA token for API calls

### ArgoCD OIDC (k8s)

Wire ArgoCD to Authentik as an OIDC provider (similar to Headlamp). Skipped until
Headlamp OIDC is confirmed working.

---

## Integration Notes

- Forgejo LFS → backed by existing Garage S3 (`forgejo` bucket)
- Authentik → Traefik `forwardAuth` middleware for future apps (not yet wired)
- All stateful services (Forgejo data, Authentik PG, Docmost PG) → VolSync daily
  backup to restic REST server at `backups.kinet.local` (Forgejo VolSync: planned)
- All credentials → SealedSecrets (`kubeseal --context admin@k8s`)

## Reference

- [Component research and comparisons](research.md)
- [User management runbook](user-management.md)
