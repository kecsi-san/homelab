---
title: "009 — Authentik as Identity Provider / SSO"
type: adr
status: accepted
scope: [k8s, k3s]
created: 2026-05-10
updated: 2026-05-17
tags: [authentik, sso, oidc, idp, oauth2, authentication]
---

# 009 — Authentik as Identity Provider / SSO

## Status

Accepted

## Context

The homelab IDP (Identity Platform) goal is a single set of credentials that works
across all internal services — Forgejo, Outline, Longhorn UI, ArgoCD, Traefik
dashboard, and future services. Without SSO, each service maintains its own user
database, password rotation is per-service, and there is no central audit log.

Requirements:
- **OIDC/OAuth2 provider**: modern apps (Forgejo, Outline) integrate via OIDC
- **Forward authentication**: Traefik middleware can protect services that have no
  built-in auth (Longhorn UI, Traefik dashboard) via `forwardAuth`
- **Declarative configuration**: blueprints or IaC for providers, flows, and property
  mappings — avoid click-ops that is lost on rebuild
- **Self-hosted**: no SaaS dependency; all identity data stays on-cluster
- **Kubernetes-native**: runs as a Pod; managed by ArgoCD
- **Single-operator friendly**: manageable without a full-time IAM team

## Decision

Use **Authentik** (`goauthentik.io`) on both clusters:

- Deployed via Helm (`charts.goauthentik.io`, version 2026.2.3) + raw manifests
- **Server** + **Worker** deployment pattern (server handles requests; worker handles
  tasks, blueprints, and outpost management)
- Standalone `redis:7-alpine` deployment (named `authentik-redis-master` to match
  Authentik's service discovery expectations without Bitnami Redis)
- PostgreSQL backend via CNPG-managed `authentik` database and role
- Blueprint ConfigMaps for declarative provider configuration (Forgejo OAuth2 provider,
  Outline OIDC provider)
- `forwardAuth` middleware wired to Authentik outpost via
  `middleware-authentik-forwardauth.yaml`; protects Longhorn UI, Traefik dashboard

Key operational notes:
- Blueprint discovery is periodic; after ConfigMap changes, restart the worker or run:
  `kubectl exec -n authentik deployment/authentik-worker -- ak apply_blueprint /blueprints/custom/<name>.yaml`
- Blueprints require `invalidation_flow` field (added in 2026.x):
  `!Find [authentik_flows.flow, [slug, default-provider-invalidation-flow]]`
- `akadmin` is the bootstrap admin; regular users created via `ak shell` (Django ORM);
  no `create_user` CLI command exists in Authentik
- `sub_mode: user_username` set on the Forgejo provider to use username as the OIDC
  `sub` claim (Forgejo requires this for stable user matching)
- Outline OIDC: requires `openid email profile` scopes and a client secret

## Alternatives Considered

| Option | Reason rejected |
|---|---|
| **Keycloak** | Most feature-complete open-source IdP; enterprise-grade OIDC/SAML/LDAP; however, JVM-based — high memory footprint (~512 MB–1 GB minimum); complex realm/client/flow configuration UI; steep learning curve for a homelab; overkill for ~5 services |
| **Kanidm** | Rust-based, modern, performant IdP; excellent LDAP support; however, smaller community, fewer pre-built integrations; OIDC/OAuth2 support is less battle-tested than Keycloak or Authentik; documentation quality lower |
| **Zitadel** | Modern, cloud-native IdP; good OIDC support; however, Go-based with its own CockroachDB or PostgreSQL dependency; less homelab community adoption; fewer blog posts and examples for the specific Forgejo + Outline integration |
| **Authelia** | Lightweight authentication + authorization proxy; excellent for `forwardAuth` use case; however, not a full OIDC IdP for app-level OIDC flows — it can act as an OIDC provider but with limitations; primarily designed as a reverse proxy auth layer |
| **Dex** | Lightweight OIDC connector that proxies to upstream providers (LDAP, GitHub, Google); not a standalone IdP — requires an upstream; not suitable as the primary identity store |
| **Basic Auth / per-service accounts** | No SSO; credential sprawl; no central audit; not scalable beyond 2-3 services |

## Consequences

**Positive:**
- Single login for all homelab services — Forgejo, Outline, Longhorn UI, Traefik
  dashboard all use Authentik credentials
- `forwardAuth` middleware enables SSO for services with no built-in OIDC support;
  adding auth to a new service is one line in its IngressRoute
- Blueprint-based provider configuration survives cluster rebuilds — declarative,
  committed to Git, re-applied automatically
- Authentik's admin UI at `authentik.kecskemethy.org` provides flow debugging, event
  logs, and user management without SSH access
- Python/Django-based — `ak shell` provides a full Python REPL against the live
  database for administrative tasks that the UI doesn't expose (user creation, bulk ops)

**Negative / Trade-offs:**
- **Bitnami Redis removed from Docker Hub** (2024): the Authentik Helm chart's default
  Redis sub-chart was Bitnami, which is no longer pullable; worked around by deploying a
  standalone `redis:7-alpine` deployment and disabling the chart's built-in Redis
- **Blueprint learning curve**: Authentik's YAML blueprint format is powerful but
  poorly documented; `!Find` references, `!Format` strings, and flow model paths require
  reading source code or community examples to get right
- **Worker restart required for blueprint changes**: the worker caches loaded blueprints;
  a `kubectl rollout restart deployment/authentik-worker` is needed after any ConfigMap
  update (or manual `ak apply_blueprint` invocation)
- **`akadmin` is not a regular user**: the bootstrap admin cannot be used for OIDC
  logins to Forgejo or Outline; regular users must be created separately via `ak shell`
- Authentik adds ~200–300 MB RAM overhead (server + worker + Redis); on a 3-node cluster
  this is acceptable but would constrain a single-node setup
- If Authentik is down, `forwardAuth`-protected services (Longhorn UI, Traefik dashboard)
  become inaccessible; this was the rationale for ensuring Authentik is a healthy, stable
  deployment before adding forwardAuth to critical infrastructure UIs
