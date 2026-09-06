---
title: "Self-Hosted Cloud Storage / File Collaboration Software"
type: research
status: active
scope: [k8s, k3s]
created: 2026-09-06
updated: 2026-09-06
tags: [cloud-storage, file-sync, opencloud, seafile, oidc, comparison]
---

# Self-Hosted Cloud Storage / File Collaboration Software

Research into self-hosted "private Google Drive" platforms (file sync, sharing, and
in-browser collaboration) as a follow-up to an OpenCloud deployment inquiry. Hard
requirements: OIDC integration with Authentik, Kubernetes deployment, Longhorn (k8s)
or local-path (k3s) PVC storage, ideally PostgreSQL (CNPG already running), and
**no PHP** (see below).

Nothing currently deployed in this category.

**No PHP, in this doc or anywhere else in this repo.** Past history with Drupal and
WordPress made this a hard exclusion, not a preference to weigh against features. A
PHP app is dropped from consideration on sight, regardless of how good its Kubernetes
story is.

---

## TL;DR

| If you want… | Choose |
|---|---|
| The best feature match for what we originally asked about | **OpenCloud** |
| Fastest raw sync, don't need groupware | **Seafile** (accept a rougher k8s path) |
| Just a web file browser with share links, no accounts/groupware | **FileBrowser Quantum** |

**Recommended try-run: OpenCloud**, deployed as a raw manifest rather than through its
now-archived community Helm chart. No PHP, no database, OIDC-native, and the closest
feature match to the original ask, though see the memory caveat under its entry below
before sizing the deployment. See Decision below.

---

## Why not OpenCloud's own Helm chart

- The app itself is fine: no DB, filesystem-backed, OIDC-native, an actively developed
  fork of ownCloud Infinite Scale, written in Go.
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
  hard k8s blockers, and this repo already runs several apps this way (forgejo,
  mealie, wikijs). The missing chart is a much smaller problem here than it would be
  in a repo that depends on Helm for everything.

---

## Previously Evaluated and Rejected

### Nextcloud

Excluded on sight: it's PHP. Otherwise it would have been the strongest candidate by
a wide margin. Its Helm chart at [nextcloud/helm](https://github.com/nextcloud/helm)
is actively maintained (not archived, 532 stars, released as recently as
`nextcloud-9.2.6` on 2026-09-04), supports Postgres and plain Traefik Ingress, and the
app itself is a strict feature superset of OpenCloud (files, calendar, contacts, Talk,
Office docs, plus a large app ecosystem). Its official docs also size for
PHP-FPM directly: roughly 80 to 120MB RAM per worker, plus 1GB for the OS and 1 to
4GB for the database, so about 8GB covers 25 concurrent users. None of that matters
given the language exclusion above.

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

### OpenCloud

| Attribute | Detail |
|---|---|
| License | Apache 2.0 |
| Language | Go |
| OIDC | Native, either the bundled LibreGraph Connect IdP or an external one (Authentik) |
| Database | None, stores everything on the filesystem |
| Kubernetes | No maintained chart (see above); raw manifests only |
| Memory | Official docs: Raspberry Pi 4B with 4GB RAM runs it for private use. Real-world reports are messier, see below. |
| CPU / Storage | No documented CPU floor found; storage is whatever the PVC needs for actual file data (32GB SD card cited for the Pi target) |
| Status | Actively developed, 5.9k stars, pushed daily |

**Pros:** No PHP, no database dependency, OIDC-native, and the closest feature match
to the original ask (files, sharing; document co-editing available via Collabora or
OnlyOffice if wanted later). Deploying it as raw manifests fits this repo's existing
pattern for apps without a great chart (forgejo, mealie, wikijs).

**Cons:** No chart to lean on and no officially blessed path to follow when something
breaks; manifests, upgrade steps, and config all have to be worked out by hand.

**Memory caveat worth knowing before the try-run:** multiple open GitHub reports
([discussion #2033](https://github.com/orgs/opencloud-eu/discussions/2033),
[issue #2128](https://github.com/opencloud-eu/opencloud/issues/2128)) describe the
process consuming all available RAM and forcing swap on 4 to 8GB machines. The root
cause traced in #2033 is the built-in Bleve search indexer: large sync or ingestion
events queue a reindexing backlog, and one user measured a 13GB resident memory peak
against a 1.5GB index during that backlog, not steady-state usage. A `GOGC=50` env
var was reported as a partial mitigation, and a maintainer suggested OpenSearch over
Bleve for larger datasets. For the try-run: set a generous memory limit rather than a
tight one, avoid dumping a huge existing file tree in on day one, and watch it in the
existing Grafana/kube-prometheus-stack rather than assuming the documented "low
requirements" apply once real files start syncing.

### Seafile

| Attribute | Detail |
|---|---|
| License | AGPL-3.0 (Community Edition); Pro edition adds features, commercial |
| Language | C/Python |
| OIDC | Supported in CE via generic OAuth/SSO config |
| Database | MySQL/MariaDB required |
| Cache | Memcached required |
| Storage | Local volume or S3-compatible object storage |
| Kubernetes | Official admin-manual page exists (`deploy_with_k8s`) but is dev-grade: raw YAML only, single replica everywhere, `hostPath` PVs (unsuitable for a multi-node cluster like this one's `kube` group), no Ingress/TLS wiring, no resource limits. No Helm chart, official or community. |
| Memory | Official minimum: 1GB RAM (plus 512MB swap). Recommended: 2GB+. Community reports put a comfortable Docker + MySQL/MariaDB baseline at 4GB, rising to 8 to 16GB with full-text search (Elasticsearch) or office-suite integration enabled. |
| CPU | Official minimum 1 core; recommended 2 cores |
| Status | Very active, huge community (15.2k★ main repo, pushed 2026-08-28) |

**Pros:** Block-level deduplication makes it the fastest of the group for sync,
especially on large or frequently-changing files. Large, established install base.

**Cons:** k8s story is a step below OpenCloud's, not above: a bare example, not a
production template. It would need the same from-scratch manifest work as OpenCloud,
plus adapting `hostPath` to Longhorn/local-path, adding Ingress/TLS by hand, and
running MySQL and Memcached alongside it. No calendar, contacts, or office-doc
collaboration either: it's a sync-and-share tool, not a groupware platform, so it
isn't a strict feature match for what OpenCloud offered.

### Pydio Cells

| Attribute | Detail |
|---|---|
| License | Split Community / Enterprise Edition |
| Language | Go |
| Database | MySQL/MariaDB, privileged user required |
| Kubernetes | Docker-first documentation; no first-class Helm chart found |
| Memory | Recommended minimum 4GB RAM plus 2 CPUs; 8GB recommended for a production deployment |
| Status | Active but modest community (2,244★, pushed 2026-09-04) |

**Notes:** Microservices architecture, aimed at compliance/enterprise document
management (granular ACLs). Smaller community than OpenCloud or Seafile for
troubleshooting, and it adds a MySQL dependency that OpenCloud doesn't need. Not
pursued further.

### FileBrowser Quantum

| Attribute | Detail |
|---|---|
| License | MIT |
| Language | Go |
| Database | None, single binary, no external dependencies |
| Kubernetes | Trivial: one Deployment plus one PVC, no chart needed |
| Memory | Typical: 100 to 500MB. Scales with indexed file count, not user count: one reported 80TB source pushed usage past 50GB during indexing. Project states 512MB as a real minimum, not an estimate. |
| Status | Actively maintained fork (8,032★, pushed 2026-09-06); the original `filebrowser/filebrowser` is being archived 2026-09-01, so this fork is now the project's continuation |

**Pros:** Same "no database, filesystem-backed" philosophy as OpenCloud, and by far
the lowest-effort thing to actually get running in k8s: no chart complexity to fight,
nothing to break on upgrade.

**Cons:** Not a groupware platform: file browsing, upload/download, and share links,
no calendar, contacts, Talk, or in-browser Office collaboration. A fair comparison
only if the actual want is "a web UI over a shared drive," not "a private Google
Drive," which was the original ask.

---

## Decision

**Try-run: OpenCloud**, deployed as raw manifests rather than through its archived
Helm chart. It's Go, has no database, is OIDC-native, and is the closest feature
match to the original ask among everything that survives the no-PHP exclusion.
Seafile's k8s story is worse than OpenCloud's own (dev-grade example manifests, extra
MySQL/Memcached dependencies, no groupware features), and FileBrowser Quantum, while
trivial to deploy, is a file browser rather than a private-cloud replacement.

Plan: a scratch Deployment plus PVC plus IngressRoute on **k3s**, OIDC wired to the
existing Authentik instance from the start (no bundled LibreGraph Connect detour,
since the integration pattern is already established for Wiki.js/Backstage), to
evaluate the UI and UX before deciding whether it's worth promoting to a proper GitOps
app on either cluster. Given the memory caveat above, start it with a generous memory
limit rather than a tight one, and don't bulk-import an existing large file tree on
day one, since the reindexing spike is what actually triggers the reported OOM
behavior, not idle running.
