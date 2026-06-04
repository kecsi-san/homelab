---
title: "010 — Forgejo as Self-Hosted Git Server"
type: adr
status: accepted
scope: [k8s, k3s]
created: 2026-05-10
updated: 2026-05-17
tags: [forgejo, git, ci-cd, oci-registry, self-hosted]
---

# 010 — Forgejo as Self-Hosted Git Server

## Status

Accepted

## Context

The homelab IDP requires a self-hosted Git platform for:
- Hosting internal repositories (Ansible roles, application code, Python projects)
- Acting as the canonical source for internal CI/CD pipelines (Forgejo Actions)
- Providing an OCI-compatible container registry (to avoid Docker Hub rate limits)
- Integrating with Authentik SSO via OAuth2/OIDC

The GitHub repository (`kecsi-san/homelab`) remains the **ArgoCD source** for GitOps
manifests — it is public and ArgoCD reads it without credentials. Forgejo hosts the
internal development work that does not need to be public.

Requirements:
- **Git hosting** with web UI, issue tracker, PR workflow
- **CI/CD**: built-in Actions (compatible with GitHub Actions syntax)
- **Container registry**: OCI image push/pull without Docker Hub
- **SSO integration**: OAuth2/OIDC via Authentik
- **Kubernetes-native**: runs as a Pod; no external database requirement beyond CNPG
- **Rootless**: no container runs as root; security-first

## Decision

Use **Forgejo** (rootless image, `codeberg.org/forgejo/forgejo:12`) on k8s:

- Deployed via raw manifests (`kube-gitops/k8s/forgejo/`)
- Rootless image: `codeberg.org/forgejo/forgejo:12` (not Gitea upstream)
- PostgreSQL backend: `forgejo` database on the CNPG cluster; credentials via SealedSecret
- App configuration via `GITEA__` environment variables (Forgejo respects Gitea's env var convention)
- `Recreate` rollout strategy (not `RollingUpdate`): LevelDB queue lock prevents two
  Forgejo pods from running simultaneously against the same PVC
- Authentik OAuth2 source registered via Authentik Blueprint + PostSync Job
- Forgejo admin user: `kecsi`; `ENABLE_REMEMBER_ME=false` (session security)
- `tea` CLI available for scriptable Forgejo API interactions

Key configuration env vars:
```
GITEA__database__DB_TYPE: postgres
GITEA__database__HOST: <cnpg-rw-service>
GITEA__server__DOMAIN: forgejo.kecskemethy.org
GITEA__server__ROOT_URL: https://forgejo.kecskemethy.org
GITEA__actions__ENABLED: true
```

## Alternatives Considered

| Option | Reason rejected |
|---|---|
| **Gitea** | Forgejo is a community fork of Gitea after the 2022 governance controversy (Gitea Dev Ltd formed, concerns about commercialisation); Forgejo is the community-governed successor; functionally similar but Forgejo receives more active community contributions; Forgejo Actions is further ahead than Gitea's equivalent |
| **GitLab CE** | Full DevOps platform (CI, registry, monitoring, wikis, issue board); however, resource-intensive (~2–4 GB RAM minimum); complex setup; most features (Kubernetes integration, advanced CI) are in EE; overkill for a homelab Git server |
| **Gogs** | Minimal, lightweight Go Git server; Gitea was forked from Gogs; Gogs lacks CI/CD, has very limited API, and minimal active development; not a viable long-term choice |
| **GitHub (continue using)** | Public repo works well for the ArgoCD GitOps source but is not suitable for private internal code; no self-hosted CI runners without GitHub Actions (cost); Docker Hub rate limits affect public image builds; misses the self-hosted learning objective |
| **Gitbucket** | JVM-based; Scala/Play framework; high memory footprint; smaller community; no native container registry; CI is a plugin |
| **Bare git + cgit** | Minimal web UI; no PR workflow, no issue tracker, no CI, no container registry; suitable only for read-only repository browsing |

## Consequences

**Positive:**
- Forgejo Actions uses GitHub Actions-compatible YAML syntax; existing GitHub Actions
  workflows can be reused with minimal modification
- Built-in OCI container registry: `forgejo.kecskemethy.org/<user>/<repo>` — eliminates
  Docker Hub dependency for internal images; rate-limit-free
- OAuth2 integration with Authentik means the same credentials work for Forgejo login
  as for other homelab services (SSO achieved)
- `tea` CLI enables scriptable repository management (create repo, manage issues, trigger
  workflows) from the workstation without browser interaction
- Rootless image removes container privilege escalation risk; aligns with PSA Restricted
  or Baseline policies

**Negative / Trade-offs:**
- **`Recreate` rollout strategy**: Forgejo uses a LevelDB queue file that acts as a
  lock; attempting a rolling update leaves the new pod in `Pending` while the old one
  holds the lock; `Recreate` causes a brief downtime (~10–20 seconds) on every update
- **Two Git servers in the homelab**: GitHub hosts the GitOps repo (public, ArgoCD
  source); Forgejo hosts internal development repos; this is intentional but requires
  discipline — ArgoCD Application manifests must always reference GitHub, not Forgejo
- **Forgejo is not yet the ArgoCD source**: the homelab GitOps repo remains on GitHub
  because ArgoCD needs to reach it from within the cluster (Forgejo is internal-only);
  migrating ArgoCD to read from Forgejo would require Forgejo to be accessible or the
  use of SSH-based repo config — a future improvement
- **Forgejo Actions ecosystem**: smaller than GitHub Actions; some third-party actions
  must be mirrored to Forgejo (`actions/checkout@v4`, `actions/setup-python@v5`) or
  the actions registry must be configured to fall back to GitHub
- PostSync Job pattern for Authentik source registration is one-directional; if the
  Authentik OAuth2 source needs changes, the Job must be re-triggered manually or the
  old source deleted first to force re-registration
