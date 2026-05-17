---
title: "Internal Developer Platform — Component Research"
type: research
status: stable
scope: [k8s, k3s]
created: 2026-05-15
updated: 2026-05-15
tags: [idp, forgejo, authentik, wiki, comparison]
---

# Internal Developer Platform — Component Research

Research for building a full self-hosted IDP on this homelab stack.
Evaluated against: 4-node bare-metal k8s (3 CP + 1 worker), existing services consuming ~1.5 GB RAM
(ArgoCD, Traefik, Longhorn, Garage, Gatus, ntfy, cert-manager, Sealed Secrets, Homepage, Glance).

---

## TL;DR — Recommended Stack

| Layer | Tool | Why |
|---|---|---|
| **Git server** | Forgejo | Community-governed Gitea fork; built-in OCI registry + Actions = 3 services in one |
| **CI/CD** | Forgejo Actions | Zero extra services; GitHub Actions YAML compatible |
| **Container + Helm registry** | Forgejo OCI (built-in) | Covered by Forgejo; add Zot only if stricter OCI compliance needed |
| **SSO / IdP** | Authentik | Native Traefik forwardAuth; OIDC for all tools; best homelab fit |
| **Documentation** | Docmost | No SSO prerequisite (unlike Outline); real-time collab; shared PG |
| **Code scanning** | Semgrep OSS + Trivy in CI | Zero persistent RAM; runs in pipeline pods |
| **Secrets** | Sealed Secrets (existing) + Vault later | Add Vault only when dynamic DB creds / PKI needed |
| **PostgreSQL** | CloudNativePG (1 cluster) | Shared by Authentik, Docmost, Forgejo, Unleash — saves ~1 GB vs per-app PG |
| **Feature flags** | Unleash (optional) | Only when applications need it |
| **Service catalog** | Skip for now | Backstage costs 3 GB for solo-homelab value achievable via Forgejo wiki |

---

## Resource Budget

### Minimal IDP (~2.5 GB additional RAM)

Forgejo + Authentik + Docmost + Semgrep/Trivy in CI + shared PostgreSQL.
A real, functional IDP. Everything else is optional.

| Component | RAM |
|---|---|
| Forgejo (git + CI + registry) | ~200 MB |
| Forgejo Actions runner | ~80 MB |
| Authentik (server + worker + Redis) | ~1.2 GB |
| Docmost | ~200 MB |
| CloudNativePG (shared, 1 primary) | ~300 MB |
| Semgrep + Trivy (CI pods, ephemeral) | 0 MB idle |
| **Total addition** | **~2.0 GB** |

### Full IDP (~11 GB additional RAM)

Everything above plus Zot, SonarQube, Vault+ESO, Unleash, Backstage.
Tight on a 4-node homelab — SonarQube and Backstage are the two heavyweights that
need justification before adding.

| Component | RAM |
|---|---|
| Minimal IDP | ~2.0 GB |
| Zot (dedicated OCI registry) | +300 MB |
| SonarQube CE | +4 GB |
| Vault + ESO | +600 MB |
| Unleash | +400 MB |
| Backstage + its PostgreSQL | +3 GB |
| **Total addition** | **~10.3 GB** |

---

## 1. Git Server

### Comparison

| | Forgejo | Gitea | GitLab CE | Gogs |
|---|---|---|---|---|
| Stars | ~7K (Codeberg) | ~46K | ~5K mirror | ~44K |
| Latest | v15.0 (Apr 2026, LTS) | Active | 17.x | Slow |
| Idle RAM | 150–200 MB | 150–250 MB | 2.5–8 GB | 80–120 MB |
| Helm chart | Official | Official | Official | Community |
| Built-in Actions/CI | Yes (GHA-compatible) | Yes | Yes | No |
| OCI/package registry | Yes | Yes (20+ formats) | Yes | No |
| Governance | Codeberg e.V. (non-profit) | For-profit (Gitea Inc.) | GitLab Inc. | Inactive |

**Forgejo** forked from Gitea in 2022 after the trademark was transferred to a for-profit entity without community consent. It is AGPL-3.0, governed by a German non-profit (Codeberg e.V.), and is now ahead of Gitea on federation (ForgeFed/ActivityPub roadmap). Functionally they are near-identical today.

**GitLab CE** is out — 2.5–8 GB for solo homelab is unjustifiable when Forgejo covers 95% of the same functionality at ~200 MB.

**Gogs** has no Actions, no package registry, and slow release cadence. Dead end for IDP use.

**Verdict: Forgejo.** Community governance matters for long-term self-hosted investment. The built-in OCI package registry and Forgejo Actions eliminate the need for separate registry and CI services.

---

## 2. CI/CD Pipeline Automation

### Comparison

| | Forgejo Actions | Woodpecker CI | Tekton | Drone CE |
|---|---|---|---|---|
| Deployment | Built into Forgejo | Server ~100 MB + agent ~30 MB | ~150 MB controller + CRDs | Maintenance mode |
| Pipeline format | GitHub Actions YAML | Own YAML | Kubernetes CRDs | Drone YAML |
| k8s backend | Yes (act runner) | Yes (first-class) | Native (IS k8s) | Yes |
| Ecosystem maturity | Growing fast | Mature | Complex | Stale |

**Forgejo Actions** runs `act`-compatible GitHub Actions YAML. Pipelines are portable (same format works on GitHub CI). The Kubernetes executor runs steps as pods — isolated, ephemeral, no shared state.

**Woodpecker CI** is the community fork of the last Apache 2.0 Drone release. More battle-tested than Forgejo Actions for complex workflows (matrix builds, fan-out), pairs natively with Forgejo via OAuth2. Worth adding alongside if you hit Forgejo Actions' current limitations.

**Tekton** is overengineered for solo homelab — pipeline steps are CRDs, setup is high, operational overhead is high. Right for a platform team building reusable task catalogs, not for one engineer.

**Drone CE** is in maintenance mode post-Harness acquisition. Do not start new deployments on it.

**Verdict: Forgejo Actions first.** Add Woodpecker CI if you need complex pipeline orchestration beyond what Actions handles well. Both can coexist.

---

## 3. Container Image Registry

### Comparison

| | Harbor | Zot | Docker Distribution (registry:2) |
|---|---|---|---|
| Stars | ~28K (CNCF Graduated) | ~900 (CNCF Sandbox) | ~9K |
| Idle RAM | 4 GB minimum (6+ containers) | 256 MB–1 GB | 50–100 MB |
| Helm chart | Official | Official | Official |
| Vulnerability scanning | Yes (Trivy backend) | Via extensions | No |
| Image signing | Yes (Cosign/Notary) | Yes (Cosign) | No |
| Web UI | Full | Minimal | None |
| OCI v1.1 spec | Yes | Yes (strict) | Partial |

**Harbor** is enterprise-grade: scanning, signing, replication, quotas, OIDC, full UI. The cost is 4 GB minimum for 6+ containers. On this homelab that's the budget of the entire minimal IDP just for a registry.

**Zot** is a single Go binary, ~300 MB RAM, strict OCI v1.1 compliance, Cosign support. Right choice if you need a dedicated registry beyond Forgejo's built-in one.

**Docker Distribution** is a pull-through cache or internal mirror. Not a full IDP registry.

**Verdict: Forgejo's built-in OCI registry covers 90% of homelab registry needs.** Add **Zot** if you need strict OCI v1.1 conformance, Cosign signing enforcement, or replication to external registries. Avoid Harbor unless you have a dedicated node with 4+ GB free.

---

## 4. Helm Chart Registry

| | ChartMuseum | OCI via Harbor/Zot | Forgejo package registry |
|---|---|---|---|
| Protocol | Legacy HTTP (index.yaml) | OCI (Helm 3.8+ native) | OCI (Helm 3.8+ native) |
| Status | Maintenance mode | Active | Active |

Harbor deprecated ChartMuseum in v2.6+ in favor of OCI. Helm 3.8+ supports `oci://` URLs natively. ArgoCD supports OCI Helm sources.

**Verdict: Forgejo's package registry is your Helm registry.** `helm push chart.tgz oci://forgejo.kecskemethy.org/yourorg` — it just works. ChartMuseum is a dead end.

---

## 5. Service Catalog

### Comparison

| | Backstage | Port (free tier) | Skip |
|---|---|---|---|
| Self-hosted | Yes | No (SaaS) | — |
| RAM | 2–4 GB (+ PostgreSQL) | Zero | — |
| Setup | Very high (build a TypeScript app) | Low | — |
| Value at solo scale | Low–medium | Medium | — |

**Backstage** is not "install and run" — you build a Backstage app, write plugins, maintain your own Docker image. It is a framework, not an appliance. For a solo/small homelab the maintenance overhead rarely pays off.

**Port free tier** (up to 15 users) gives you a functional catalog with a Kubernetes plugin at zero infrastructure cost. The tradeoff: external SaaS dependency.

**Verdict: Skip for now.** A well-maintained Forgejo wiki + ArgoCD app list + `CLAUDE.md` covers 80% of catalog value. If you grow to 3+ engineers and feel the friction, start with Port's free tier before committing to self-hosted Backstage.

---

## 6. Documentation / Wiki

### Comparison

| | Docmost | Outline | BookStack | Wiki.js |
|---|---|---|---|---|
| Stars | ~18K | ~29K | ~14K | ~24K |
| Idle RAM | ~200 MB (+ shared PG) | ~300 MB (+ shared PG) | ~200 MB (+ MySQL) | ~200 MB (+ DB) |
| Auth prerequisite | None (email+password built-in) | OIDC required (no built-in auth) | LDAP/SAML | Many backends |
| Real-time collab | Yes | Yes | No | No |
| SSO integration | OIDC | OIDC/SAML | LDAP/SAML | Many |
| Helm chart | Unofficial | Community | Community | Official |

**Outline** is the most polished Notion-like editor. Critical friction: the self-hosted version has no built-in email+password auth — you must have an OIDC provider running before Outline works at all. Deploy Authentik first, then Outline.

**Docmost** was built specifically to fix this: native email+password, real-time collaboration, Draw.io/Mermaid/Excalidraw, and OIDC available but optional. 18K stars in a few years signals rapid community adoption. Best choice if you deploy wiki before SSO.

**BookStack** suits structured, hierarchy-based docs (runbooks, SOPs) but has no real-time collab.

**Wiki.js** is showing its age; 3.x rewrite has been slow.

**Verdict: Docmost** — no SSO prerequisite, real-time collab, shares PostgreSQL with Authentik. Switch to **Outline** if you have Authentik running and prefer its editing experience.

---

## 7. Static Code Analysis / Security Scanning

### Comparison

| | SonarQube CE | Semgrep OSS | Trivy + Grype + Syft |
|---|---|---|---|
| RAM (persistent) | 2–4 GB | ~200 MB (or 0 if CLI-only) | 0 MB idle |
| Purpose | Code quality + SAST | SAST (security-focused) | SCA, CVE, SBOM |
| Detection rate | ~19% (DAST benchmark) | ~46% (DAST benchmark) | N/A (not SAST) |
| Quality dashboards | Yes (debt trends, gates) | No | No |
| CI integration | Plugin | CLI step | CLI step |

**SonarQube CE** is the most complete quality dashboard (debt trends, PR decoration, quality gates) but costs 2–4 GB RAM permanently. Elasticsearch alone needs 512 MB minimum heap.

**Semgrep OSS** runs as a CLI in CI pods — no persistent service. Security detection rate 2× SonarQube on benchmarks. `semgrep scan --config=auto` covers OWASP rules, secrets detection, and community rules.

**Trivy+Grype+Syft** is a different category — container vulnerability scanning and SBOM generation, not SAST. Trivy is already in this repo.

**Verdict: Semgrep OSS + Trivy in CI pipelines — zero idle RAM cost.** Add SonarQube only if quality dashboards and debt tracking over time become a real need, and tune `sonarqube.es.javaOpts: -Xms512m -Xmx512m` to get idle RAM to ~2 GB.

---

## 8. SSO / Identity Provider

### Comparison

| | Authentik | Keycloak | Dex |
|---|---|---|---|
| Stars | ~14K | ~22K | ~9K |
| Language | Python + Go outpost | Java (Quarkus) | Go |
| Idle RAM | ~1.2–1.5 GB total (server + worker + Redis + PG) | ~1–1.5 GB | ~50–100 MB |
| Full user management | Yes | Yes | No (broker only) |
| Traefik forwardAuth native | Yes (built-in outpost) | Needs oauth2-proxy | No |
| OIDC / SAML | Yes | Yes | OIDC only |
| UI complexity | Moderate (visual flow designer) | High (realms/clients/mappers) | None (config file) |

**Authentik** has a visual authentication flow designer, a proxy outpost that plugs directly into Traefik's `forwardAuth` middleware, and first-class OIDC support for ArgoCD, Forgejo, Headlamp, Gatus, and wiki tools. The 2026.2.x release has a known memory regression (~1 GB workers) — consider pinning to 2025.12.x until resolved.

**Keycloak** is the enterprise standard. The Quarkus rewrite improved the old WildFly-era 800 MB+ idle, but it still lands at 1–1.5 GB. The realm/client/mapper paradigm is more complex than Authentik for basic SSO use cases. Choose it if you need SAML federation to corporate IdPs, complex attribute mapping, or deep enterprise audit requirements.

**Dex** is a pure OIDC broker — not a user store, no user management UI. Right choice only if you already have a corporate LDAP/SAML upstream and just need a k8s API server OIDC bridge.

**Verdict: Authentik.** Native Traefik integration, manageable admin UI, and OIDC support for every tool in this stack. Budget ~1.5 GB total including shared PostgreSQL and built-in Redis.

---

## 9. Secrets Management

### Should Vault be added on top of Sealed Secrets?

| | Sealed Secrets (existing) | Vault | External Secrets Operator |
|---|---|---|---|
| Purpose | GitOps-safe secret commit | Dynamic secrets, PKI, lease management | Sync secrets from external stores into k8s |
| RAM | ~50 MB (running) | ~256–512 MB | ~100 MB |
| Operational overhead | Low | High (unseal automation, policies, leases) | Medium |
| Dynamic DB credentials | No | Yes | No (backend-dependent) |
| Adds value when | — | DB creds + PKI + multi-runtime secrets | When Vault or cloud KMS exists |

**Sealed Secrets** already solves GitOps-committed secrets cleanly. It covers all current needs.

**Vault** adds real value when: (1) you run a PostgreSQL cluster and want auto-rotating short-lived credentials per service, (2) you want an internal PKI CA issuing mTLS certs, (3) secret consumers exist outside Kubernetes (VMs, scripts, CI).

**ESO** is the Kubernetes-side companion to Vault — it syncs Vault secrets into k8s Secrets automatically.

**Verdict: Keep Sealed Secrets. Add Vault when you deploy the shared CloudNativePG cluster** — its dynamic secrets engine immediately pays for itself via automatic credential rotation. Deploy Vault in single-node Raft mode first; migrate to 3-replica HA later. Use ESO alongside for clean injection. ~600 MB total addition.

---

## 10. Feature Flags (Optional)

| | Unleash | GrowthBook | Flagsmith |
|---|---|---|---|
| Stars | ~13K | ~6K | ~4.5K |
| Idle RAM | ~300 MB (+ shared PG) | ~400 MB (+ MongoDB) | ~200 MB (+ PG) |
| A/B testing | No | Yes (built-in stats) | Limited |
| OpenFeature provider | Yes | Yes | Yes |
| License | Apache-2.0 | MIT | BSD-3 |

**Unleash** is the most mature OSS feature flag platform. Shares PostgreSQL. Best default if you need deployment control (gradual rollouts, kill switches, user segments).

**GrowthBook** is uniquely valuable if you also need A/B testing with statistical analysis. Hard dependency on MongoDB.

**Verdict: Unleash** if/when applications need feature flags. Skip entirely for infrastructure-only workloads.

---

## Recommended Build Order

Deploy in this sequence — each step unblocks the next:

1. **CloudNativePG** — shared PostgreSQL cluster. Everything stateful depends on it.
2. **Forgejo** — git server + OCI registry + Actions runner. This is the platform foundation.
3. **Authentik** — SSO gates access to everything that follows. Wire Forgejo OIDC immediately.
4. **Forgejo Actions runners** — CI pipelines are now unlocked with SSO-secured Forgejo.
5. **Docmost** — documentation shares PostgreSQL, gains OIDC login from Authentik.
6. **Semgrep + Trivy** — add as steps in Forgejo Actions pipelines. Zero new services.
7. **Vault + ESO** — after PostgreSQL cluster is up and dynamic credential rotation is useful.
8. **Zot** — if OCI compliance or Cosign signing enforcement becomes a requirement.
9. **SonarQube** — if code quality dashboards justify 4 GB RAM.
10. **Unleash** — when applications need feature flags.
11. **Backstage** — only if growing beyond solo operation and catalog value justifies 3 GB.

---

## Integration Notes for This Stack

- **Garage S3 as Forgejo LFS backend** — Forgejo supports S3-compatible storage for Git LFS. Point at the existing Garage instance (`volsync-backups` bucket or a new `forgejo` bucket). No Longhorn PVC for large files.
- **Authentik forwardAuth in Traefik** — replaces any need for oauth2-proxy. One Authentik outpost per cluster. `forwardAuth` middleware in IngressRoutes gates any service behind SSO without changes to the app.
- **VolSync for stateful IDP services** — extend the existing VolSync backup schedule to cover Forgejo data, Authentik PostgreSQL, Docmost PostgreSQL, and Vault Raft storage. Same restic REST server at `backups.kinet.local`.
- **Sealed Secrets for IDP bootstrapping** — Authentik admin credentials, PostgreSQL passwords, Forgejo admin token, SMTP config all go through `kubeseal --context admin@k8s` before committing.
- **Forgejo webhook → ArgoCD sync** — configure `argocd-cm` to accept Forgejo webhooks. Push-to-main triggers ArgoCD sync immediately without waiting for the 3-minute poll interval.
- **Authentik memory regression (2026.2.x)** — known issue, workers doubled from ~500 MB to ~1 GB. Pin Authentik to `2025.12.x` until upstream confirms a fix.
