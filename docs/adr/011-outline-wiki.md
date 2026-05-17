---
title: "011 — Outline as Team Wiki"
type: adr
status: accepted
scope: [k8s]
created: 2026-05-17
updated: 2026-05-17
tags: [outline, wiki, documentation, oidc, knowledge-base]
---

# 011 — Outline as Team Wiki

## Status

Accepted

## Context

The homelab IDP stack needed a self-hosted wiki or knowledge base for structured
documentation that goes beyond Markdown files in a Git repo. Use cases: runbooks,
how-to guides, team knowledge sharing, and living documents that benefit from a rich
text editor and search rather than raw Markdown in a code editor.

Requirements:
- **Rich text editor**: real-time collaborative editing with a modern WYSIWYG interface
- **OIDC/OAuth2 SSO**: integrate with Authentik; no per-service password required
- **Self-hosted**: all data stays on-cluster; no SaaS
- **Kubernetes-native**: runs as a Pod; managed by ArgoCD
- **PostgreSQL backend**: use existing CNPG cluster (not SQLite or MongoDB)
- **Document hierarchy**: nested collections, not flat wikis

## Decision

Use **Outline** (Community Edition, `docker.getoutline.com/outlinewiki/outline:latest`)
deployed on k8s:

- Deployed via raw manifests (`kube-gitops/k8s/outline/`)
- PostgreSQL backend: `outline` database on CNPG cluster; credentials via SealedSecret
- Redis: standalone `redis:7-alpine` in the `outline` namespace (same pattern as Authentik)
- OIDC via Authentik: `OIDC_CLIENT_ID`, `OIDC_CLIENT_SECRET` from SealedSecret;
  discovery URL `https://authentik.kecskemethy.org/application/o/outline/.well-known/openid-configuration`
- S3-compatible storage: Outline stores file attachments; configured to use local storage
  (`FILE_STORAGE: local`) until Garage S3 integration is set up
- `SECRET_KEY` and `UTILS_SECRET` from SealedSecret

Key env vars:
```
NODE_ENV: production
DATABASE_URL: postgres://<user>:<pass>@<cnpg-rw>:5432/outline
REDIS_URL: redis://redis:6379
URL: https://outline.kecskemethy.org
OIDC_AUTH_URI: https://authentik.kecskemethy.org/application/o/authorize/
OIDC_TOKEN_URI: https://authentik.kecskemethy.org/application/o/token/
OIDC_USERINFO_URI: https://authentik.kecskemethy.org/application/o/userinfo/
OIDC_SCOPES: openid email profile
```

## Why Outline Replaced Docmost

Outline was selected after **Docmost** was initially deployed and then removed.
Docmost is a newer, self-hosted wiki that appeared in early 2024 as an alternative to
Notion/Outline. The decision to switch was driven by a critical limitation discovered
after deployment:

**Docmost's OIDC/SSO requires the Enterprise Edition (EE) license.**

The Community Edition of Docmost supports only email/password and "magic link" (email
link) authentication. OIDC integration — required for Authentik SSO — is gated behind
EE. This was not clearly communicated on the project website or Helm chart
documentation at the time of evaluation; it was discovered during OIDC configuration
when the OIDC settings were absent from the UI and the GitHub issue tracker confirmed
EE-only status.

Outline's Community Edition includes full OIDC support at no cost.

## Alternatives Considered

| Option | Reason rejected |
|---|---|
| **Docmost** | Initially deployed; removed after discovering OIDC SSO requires EE license; Community Edition limited to email/password auth only — incompatible with the Authentik SSO requirement |
| **Wiki.js** | Feature-rich wiki with OIDC support; however, requires MongoDB or PostgreSQL; the v3 rewrite (Karma) has been in development for years with no stable release; v2 is mature but the uncertain roadmap is a risk |
| **BookStack** | PHP/Laravel-based; familiar MediaWiki-like structure; SSO via SAML2/OIDC supported; however, PHP stack diverges from the Go/Node ecosystem in this homelab; less modern editor experience than Outline |
| **Confluence** | Industry standard; expensive; SaaS or self-hosted (Data Center tier); not suitable for a homelab |
| **Notion** | SaaS only; no self-hosted option; all data off-premises |
| **Git + Markdown (continue)** | Already in use for structured ADRs and research docs; good for developer-centric documentation but lacks rich text editing, real-time collaboration, and search across documents; not suitable for non-developer team members |

## Consequences

**Positive:**
- Outline Community Edition includes full OIDC; Authentik SSO works out of the box
  with the standard `openid email profile` scope set
- Real-time collaborative editing; document search across all content; nested
  collections with emoji icons — significantly better UX than raw Markdown for
  operational runbooks and team-facing documentation
- Outline at `outline.kecskemethy.org` is SSO-protected; users must authenticate
  via Authentik before accessing any document

**Negative / Trade-offs:**
- **The Docmost detour**: deploying, configuring, and then removing Docmost cost ~1 day
  of work; the OIDC EE limitation should have been verified before deployment. Going
  forward: always verify SSO/OIDC licensing status before deploying a new service.
- **File attachments**: `FILE_STORAGE: local` stores attachments in a PVC; this is
  not replicated beyond Longhorn's 2-replica setup. Migrating to Garage S3 would
  improve durability but requires additional configuration.
- Outline does not have a CLI or GitOps-friendly import; documents cannot be managed
  declaratively via manifests — content is stored in the PostgreSQL database
- Outline's `latest` tag can introduce breaking changes; pinning to a specific version
  tag is recommended once the deployment is stable
