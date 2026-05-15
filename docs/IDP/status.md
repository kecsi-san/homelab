# IDP Status

## Decision

Deploy a minimal IDP to **k3s** and the same minimal IDP **plus Backstage** to **k8s**.

---

## Component Plan

### Minimal IDP — both clusters (k3s + k8s)

| Component | Tool | Layer | Status |
|---|---|---|---|
| Shared database | CloudNativePG | Infrastructure | Done |
| Git server + OCI registry + CI | Forgejo | Platform | Done |
| CI runners | Forgejo Actions | Platform | Planned |
| SSO / Identity Provider | Authentik | Platform | Planned |
| Documentation / wiki | Docmost | Platform | Planned |
| Code analysis (SAST) | Semgrep OSS (CI step) | Quality | Planned |
| Vulnerability scanning | Trivy (CI step) | Quality | Planned |

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

## Integration Notes

- Forgejo LFS → backed by existing Garage S3 (`forgejo` bucket)
- Authentik outpost → Traefik `forwardAuth` middleware; no oauth2-proxy needed
- All stateful services (Forgejo data, Authentik PG, Docmost PG, Vault Raft) → VolSync daily backup to restic REST server at `backups.kinet.local`
- All credentials → SealedSecrets (`kubeseal --context admin@k8s`)
- Authentik 2026.2.x memory regression known — pin to `2025.12.x` until upstream fix

## Reference

- [Component research and comparisons](research.md)
