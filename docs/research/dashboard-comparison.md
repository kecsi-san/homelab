---
title: "Homelab Dashboard Comparison"
type: research
status: stable
scope: [general]
created: 2026-05-15
updated: 2026-05-15
tags: [dashboard, kubernetes, comparison]
---

# Homelab Dashboard Comparison

Comparison of self-hosted dashboard options evaluated against the current homelab stack
(Kubernetes 1.35 + ArgoCD + Traefik, 4-node bare-metal cluster).

**Current:** Homepage v1.13 — deployed, working, RBAC-integrated.

---

## TL;DR

| Tool | Keep / Add / Skip | Reason |
|------|-------------------|--------|
| **Homepage** | **Keep (primary)** | Best k8s integration, 100+ service APIs, already configured |
| **Glance** | Add if you want feeds | RSS/news/Reddit aggregation — different purpose, not a replacement |
| **Homarr** | Skip | Good GUI, but no advantage over Homepage for YAML-GitOps workflows |
| **Dashy** | Skip | Weaker k8s story, higher resource use than Homepage |
| **Hajimari** | Skip | Abandoned since 2022 |

---

## Feature Comparison Table

| Feature | Homepage | Glance | Homarr | Dashy | Hajimari |
|---------|----------|--------|--------|-------|----------|
| **GitHub stars** | 30k | 34k | 4k | 25k | 0.8k |
| **Latest release** | v1.13 (May 2026) | v0.8.4 (Jun 2025) | v1.61 (May 2026) | v4.0 (Apr 2026) | v2.0.2 (Oct 2022) ⚠️ |
| **Language / stack** | Next.js | Go | TypeScript | Vue.js | Go + Svelte |
| **K8s service discovery** | ✅ Native (annotations, RBAC) | ❌ None | ✅ Partial (ingress/pods) | ❌ None | ✅ Native (CRDs) |
| **Pod health / stats** | ✅ Label selector | ❌ | ✅ (Metrics Server) | ❌ | ✅ |
| **Service integrations** | 100+ APIs | ~15 | 40+ | 50 widgets | Ingress-based |
| **RSS / news feeds** | ❌ | ✅ Core feature | ❌ | ❌ | ❌ |
| **Feed sources** | — | RSS, Reddit, HN, YouTube, Twitch, GitHub releases | — | — | — |
| **Built-in auth** | ❌ (by design) | ❌ | ✅ (OIDC, LDAP) | ✅ (SHA-256, Keycloak) | ❌ |
| **Config method** | YAML files | Single YAML | Drag-and-drop GUI | YAML + visual editor | K8s annotations + CRDs |
| **GitOps-friendly** | ✅ | ✅ | ⚠️ (state in DB) | ✅ | ✅ |
| **Helm chart** | Unofficial | ❌ | ✅ Official | ❌ | ✅ Official |
| **RAM footprint** | ~200MB | <50MB | ~600MB | ~250MB | Lightweight |
| **Background image** | ✅ | ✅ | ✅ | ✅ | Limited |
| **Custom CSS/JS** | ✅ | ✅ | Limited | ✅ | ❌ |
| **Multi-page layout** | ❌ (single page) | ✅ | ✅ | ✅ | ❌ |
| **Mobile / PWA** | Responsive | Responsive | Responsive | PWA | Responsive |
| **License** | GPL-3.0 | AGPL-3.0 | Apache-2.0 | MIT | Apache-2.0 |

---

## Per-Tool Detail

### Homepage — current choice

**Strengths for this stack:**
- Native Kubernetes RBAC: discovers pods/services by label selector, shows real CPU/memory per app
- 100+ first-party service integrations (Longhorn, ArgoCD, Traefik all have dedicated widgets)
- YAML config lives in git alongside ArgoCD app manifests — single source of truth
- API keys proxied server-side (browser never sees credentials)
- Statically generated — near-instant page loads

**Weaknesses:**
- No built-in auth — fine for LAN-only, Traefik handles this
- No RSS/news/feed aggregation
- Single-page only (no multi-tab layout)
- Unofficial Helm chart (jameswynn) — works but not maintained by core team

---

### Glance — complementary option

**Strengths:**
- Purpose-built for feed aggregation: RSS, Reddit, Hacker News, YouTube, Twitch, GitHub releases, weather, stocks
- Extremely lightweight (<50MB RAM, single Go binary)
- Multiple pages — can mix feed widgets and service links on different tabs
- Good for a "what's happening" personal dashboard alongside the infra dashboard

**Weaknesses:**
- Zero native Kubernetes integration — no pod health, no service discovery
- No official Helm chart — would need raw manifests
- Duplicates what Homepage already does for service links
- AGPL-3.0 license

**When to add:** If you want an RSS reader / news aggregator as a second tab. Does not replace Homepage.

---

### Homarr

**Strengths:**
- Drag-and-drop GUI — no YAML editing required
- Built-in auth (OIDC, LDAP) — useful for multi-user setups
- Has an official Helm chart
- *arr stack integration depth

**Weaknesses:**
- GUI-first design conflicts with GitOps: dashboard state lives in a database, not git
- Lower integration count than Homepage (40 vs 100+)
- Higher RAM (~600MB) for equivalent functionality
- Weaker k8s story than Homepage despite partial support
- At 4k stars it's less battle-tested than Homepage/Dashy

**Verdict:** Good tool for teams that don't want YAML. Not a fit here — GitOps YAML is the workflow.

---

### Dashy

**Strengths:**
- Built-in auth (SHA-256, Keycloak SSO, multi-user)
- Visual JSON editor + YAML — best of both worlds for config
- PWA with offline access
- 50 widgets, 25+ languages

**Weaknesses:**
- No native Kubernetes integration — no pod health or service discovery
- Higher RAM than Homepage for equivalent service-link features
- Weaker widget ecosystem depth than Homepage for homelab APIs
- No Helm chart

**Verdict:** Strong for UI-heavy customization and auth, but Homepage beats it specifically for k8s monitoring.

---

### Hajimari

**Strengths:**
- Purest Kubernetes-native design: reads Ingress annotations and CRDs, zero manual service config
- RBAC-based discovery that mirrors how ArgoCD itself works
- Lightweight Go + Svelte

**Weaknesses:**
- **Last release: October 2022 — effectively abandoned**
- No built-in auth
- Very limited widget ecosystem
- Only 822 stars — small community

**Verdict:** Architecturally elegant but dead project. Skip.

---

## Running Multiple Dashboards

The only combination that makes practical sense for this homelab:

**Homepage (infra) + Glance (personal feeds)**

- Homepage: service health, cluster stats, links to all k8s apps
- Glance: RSS feeds, GitHub releases, news, weather, HN — personal "what's new" page
- Both are YAML-configured and GitOps-friendly
- Combined RAM: ~250MB — acceptable
- Each has a distinct purpose with zero overlap

All other combinations add complexity without filling a gap.

---

## Decision for This Homelab

**Keep Homepage.** The Kubernetes integration depth, 100+ service APIs, and YAML-GitOps fit are exactly right for this stack. No other tool matches it on all three.

**Glance is worth adding if** a personal feed aggregator (news, GitHub release tracking, HN, Reddit) would get regular use. It costs one new ArgoCD app and ~50MB RAM.

**Everything else:** skip.
