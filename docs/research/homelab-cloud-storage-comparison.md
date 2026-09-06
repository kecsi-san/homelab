---
title: "Self-Hosted Cloud Storage / File Collaboration Software"
type: research
status: active
scope: [k8s, k3s]
created: 2026-09-06
tags: [cloud-storage, file-sync, opencloud, nextcloud, seafile, oidc, comparison]
---

# Self-Hosted Cloud Storage / File Collaboration Software

Research into self-hosted "private Google Drive" platforms (file sync, sharing, and
in-browser collaboration) as a follow-up to an OpenCloud deployment inquiry. Hard
requirements: OIDC integration with Authentik, Kubernetes deployment, Longhorn (k8s)
or local-path (k3s) PVC storage, ideally PostgreSQL (CNPG already running).

Nothing currently deployed in this category.

---

## TL;DR

| If you want… | Choose |
|---|---|
| Best feature completeness + best-maintained k8s story | **Nextcloud** |
| Fastest raw sync, don't need groupware | **Seafile** (accept a rougher k8s path) |
| Just a web file browser with share links, no accounts/groupware | **FileBrowser Quantum** |
| What we originally asked about | **OpenCloud**, see verdict below |

**Recommended try-run: Nextcloud.** It's the only candidate here with an actively
maintained, non-archived Kubernetes chart, and it's a strict feature superset of
OpenCloud (files, calendar, contacts, Talk, Office docs, plus a large app ecosystem),
at the cost of a heavier stack (PHP-FPM, MySQL/Postgres, optional Redis).

---

## Why not OpenCloud (recap)

- The app itself is fine: no DB, filesystem-backed, OIDC-native, an actively developed
  fork of ownCloud Infinite Scale.
- **No official Kubernetes support.** Docs only cover Docker/Docker Compose and
  bare-metal.
- The only Kubernetes path, the community Helm chart
  ([opencloud-eu/helm](https://github.com/opencloud-eu/helm)), was **archived
  2025-11-26** by its own maintainers, citing "a high amount of AI generated
  contributions and poor maintenance." Production-ready k8s charts are now a paid
  enterprise offering (contact sales@opencloud.eu).
- Forks that turned up in search (`michaelstingl/opencloud-eu-helm`, etc.) are
  pre-archival snapshots from the same date, not actively continued.
- Hand-rolling raw manifests (Deployment, PVC, IngressRoute) is viable; the app has no
  hard k8s blockers. But there's no chart to lean on and no officially blessed path to
  follow when something breaks.

---

## Previously Evaluated and Rejected

### ownCloud Infinite Scale (oCIS)

- The upstream project OpenCloud itself forked from, after ownCloud's 2024 acquisition
  by US-based Kiteworks. A 2026 comparison piece on
  [MassiveGRID](https://massivegrid.com/blog/nextcloud-vs-owncloud-vs-seafile-enterprise-comparison/)
  flags sovereignty concerns, an uncertain product roadmap, and a shrinking community
  as reasons not to pick the original over its fork.
- Same architecture as OpenCloud, worse governance story. Not worth evaluating
  separately.

### Twake Drive

- Linagora, AGPL-3.0, 981 stars, active commits (pushed 2026-09-04).
- Smaller and newer than the others here. Couldn't find a Kubernetes or Helm story at
  all on a first pass, only Docker-oriented docs. Worth a second look once it matures,
  not worth spending try-run time on now.

---

## Active Candidates

### Nextcloud

| Attribute | Detail |
|---|---|
| License | AGPL-3.0 |
| OIDC | Not a Helm value, but a well-trodden path via the official `user_oidc` app. Authentik integration is a common, well-documented community pattern (same shape as the Wiki.js/Backstage integrations already running here). |
| Database | MySQL/MariaDB or **PostgreSQL** (fits CNPG); SQLite by default, not for production |
| Cache | Redis, optional, packaged as a Bitnami subchart or pointable at an external instance |
| Storage | Local PVC (RWO; RWX needed only for multi-replica) or S3/Swift as primary storage |
| Kubernetes | **Actively maintained** community Helm chart at [nextcloud/helm](https://github.com/nextcloud/helm): not archived, 532 stars, releases as recently as `nextcloud-9.2.6` (pushed 2026-09-04) |
| Ingress | Plain Kubernetes Ingress with Traefik/NGINX/HAProxy annotations, no Gateway API requirement unlike OpenCloud's chart |
| Status | Massive, very active project. Huge app ecosystem (Calendar, Contacts, Talk, Office via Collabora/OnlyOffice). |

**Pros:** By far the best feature completeness (files, calendar, contacts, chat,
in-browser Office docs, and a large app store on top), and the best-maintained k8s
deployment path of anything researched here. Fits existing infra directly: Postgres
via CNPG, Longhorn/local-path PVC, Traefik ingress, Authentik via `user_oidc`.

**Cons:** Heaviest stack of the bunch, PHP-FPM plus opcache tuning, a database, and
(recommended) Redis, versus OpenCloud's zero-dependency filesystem model. The chart
sets no default resource limits, and the admin manual explicitly warns to back up
before every upgrade and to upgrade major versions incrementally.

### Seafile

| Attribute | Detail |
|---|---|
| License | AGPL-3.0 (Community Edition); Pro edition adds features, commercial |
| OIDC | Supported in CE via generic OAuth/SSO config |
| Database | MySQL/MariaDB required |
| Cache | Memcached required |
| Storage | Local volume or S3-compatible object storage |
| Kubernetes | Official admin-manual page exists (`deploy_with_k8s`) but is dev-grade: raw YAML only, single replica everywhere, `hostPath` PVs (unsuitable for a multi-node cluster like this one's `kube` group), no Ingress/TLS wiring, no resource limits. No Helm chart, official or community. |
| Status | Very active, huge community (15.2k★ main repo, pushed 2026-08-28) |

**Pros:** Block-level deduplication makes it the fastest of the group for sync,
especially on large or frequently-changing files. Large, established install base.

**Cons:** k8s story is a step below OpenCloud's, not above: a bare example, not a
production template. It would need the same from-scratch manifest work as OpenCloud,
plus adapting `hostPath` to Longhorn/local-path and adding Ingress/TLS by hand. No
calendar, contacts, or office-doc collaboration either: it's a sync-and-share tool, not
a groupware platform, so it isn't a strict feature match for what OpenCloud offered.

### Pydio Cells

| Attribute | Detail |
|---|---|
| License | Split Community / Enterprise Edition |
| Database | MySQL/MariaDB, privileged user required |
| Kubernetes | Docker-first documentation; no first-class Helm chart found |
| Status | Active but modest community (2,244★, pushed 2026-09-04) |

**Notes:** Go microservices architecture, aimed at compliance/enterprise document
management (granular ACLs). Smaller community than Nextcloud or Seafile for
troubleshooting. Not pursued further, since Nextcloud already covers this ground with
a much larger ecosystem.

### FileBrowser Quantum

| Attribute | Detail |
|---|---|
| License | MIT |
| Database | None, single binary, no external dependencies |
| Kubernetes | Trivial: one Deployment plus one PVC, no chart needed |
| Status | Actively maintained fork (8,032★, pushed 2026-09-06); the original `filebrowser/filebrowser` is being archived 2026-09-01, so this fork is now the project's continuation |

**Pros:** Closest to OpenCloud's "no database, filesystem-backed" philosophy, and by
far the lowest-effort thing to actually get running in k8s: no chart complexity to
fight, nothing to break on upgrade.

**Cons:** Not a groupware platform: file browsing, upload/download, and share links,
no calendar, contacts, Talk, or in-browser Office collaboration. A fair comparison only
if the actual want is "a web UI over a shared drive," not "a private Google Drive."

---

## Decision

**Try-run: Nextcloud**, via the official [nextcloud/helm](https://github.com/nextcloud/helm)
chart. It's the best match for what OpenCloud was trying to offer (a full
private-cloud feature set), and the only candidate here with a Kubernetes deployment
story actually worth trusting today. Plan: a disposable `helm install` into a scratch
namespace on **k3s** (self-contained Postgres/Redis via the chart's own subcharts, not
wired into the shared CNPG cluster or Authentik yet) to evaluate the UI and UX before
deciding whether it's worth promoting to a proper GitOps app with real OIDC, Longhorn,
and Traefik integration.
