---
title: "Self-Hosted Wiki / Documentation Software"
type: research
status: active
scope: [k8s, k3s]
created: 2026-05-31
updated: 2026-05-31
tags: [wiki, documentation, outline, wikijs, affine, xwiki, oidc, comparison]
---

# Self-Hosted Wiki / Documentation Software

Research into self-hosted wiki and documentation platforms for the homelab.
Hard requirements: OIDC integration with Authentik, Kubernetes deployment,
PostgreSQL preferred (CNPG already running).

Current install: **Outline 1.7.1**: working but under review (BSL 1.1 license, community Helm chart only).

---

## TL;DR

| If you want… | Choose |
|---|---|
| Best drop-in replacement, truly OSS | **Wiki.js v2** |
| Best editor, least migration work | **Stay on Outline** |
| Traditional enterprise wiki, truly OSS | **XWiki** |
| Future-watch (not ready yet) | **AFFiNE** |

---

## Previously Evaluated and Rejected

### Docmost CE
- **OIDC is Enterprise Edition (paid) only**: Community Edition is email/password only.
  This was only discovered after deployment when OIDC settings were absent from the UI.
- Deployed briefly, then removed.
- Reference: https://docmost.com/docs/editions

### BookStack
- **Requires MySQL/MariaDB; no PostgreSQL support.**
- PHP/Laravel stack diverges from the Go/Node ecosystem used in this homelab.
- No real-time collaboration.

### Wiki.js v3
- Has been in alpha since October 2022 with no stable release and no published ETA.
- Community frustration is high. Not a viable option until it actually ships.

### Git + Markdown (docs/)
- In use for ADRs, research notes, runbooks; appropriate for that purpose.
- Not suitable as a living team wiki: no real-time editing, no rich-text experience,
  PR review overhead for casual notes.

---

## Active Candidates

### Outline (current install: v1.7.1)

| Attribute | Detail |
|---|---|
| License | BSL 1.1 (source-available; auto-converts to Apache 2.0 after 4 years) |
| OIDC | Built-in, mandatory; no login without OIDC/SAML. Authentik integration working. |
| Database | PostgreSQL + Redis |
| Storage | Local PVC or S3/MinIO |
| Kubernetes | Community Helm charts only (encircle360, kubitodev). No official chart. |
| Editor | Best-in-class Notion-like block editor. Slash commands, drag-and-drop, real-time collab. |
| Status | Actively developed. Frequent releases. YC-backed. |

**Pros:** Best editor of all options. Authentik OIDC already wired and working.
Active development. Good search. Real-time collaboration.

**Cons:** BSL 1.1 is not OSI-approved open source (restricts commercial re-hosting,
not personal self-hosting). No official Helm chart; community charts may lag releases.
Redis required as a separate dependency. Editor is a Notion clone; unusual feel if you
are used to traditional wiki tools. Design is minimal; dark mode is very high-contrast
(no theme customisation in CE).

**Note on the BSL restriction:** The BSL 1.1 only prohibits *commercial hosting of Outline
as a product*. Personal and team self-hosting is explicitly permitted. The license converts
to Apache 2.0 four years after each release. This is a philosophical/optics concern for a
homelab, not a legal one.

---

### Wiki.js v2

| Attribute | Detail |
|---|---|
| License | AGPL-3.0 |
| OIDC | Built-in, free. Authentik has an official integration guide. Multiple auth strategies can coexist. |
| Database | PostgreSQL (preferred), MySQL, MariaDB, SQLite |
| Kubernetes | Official Helm chart: `helm repo add requarks https://charts.js.wiki` |
| Editor | Block editor + Markdown + visual editor + AsciiDoc |
| Status | **Maintenance mode**: security and bug fixes only; feature development stopped pending v3. Latest: v2.5.314 (May 2026). |

**Pros:** AGPL-3.0 (genuinely open source). PostgreSQL. Official Helm chart.
Official Authentik integration documentation. Lightweight (~200 MB RAM).
Multiple editor modes (Markdown, visual, block).

**Cons:** Feature-frozen; no new features will ship on v2. v3 is still alpha with no ETA;
if it never ships, a future migration would be needed again. Editor is competent but
not as polished as Outline's block editor.

**Authentik integration:** https://integrations.goauthentik.io/documentation/wiki-js/

---

### XWiki

| Attribute | Detail |
|---|---|
| License | LGPL 2.1 |
| OIDC | Official OIDC Authenticator extension (`xwiki-contrib/oidc`); free, open source. Authentik integration is feasible via community documentation. |
| Database | PostgreSQL (also MySQL/MariaDB) |
| Kubernetes | Official Helm chart: `xwiki-contrib/xwiki-helm`. Actively maintained. |
| Editor | WYSIWYG + Markdown + wiki syntax. Traditional wiki model, not Notion-style blocks. |
| Status | Mature 20-year project. Active. Strong enterprise adoption. |

**Pros:** LGPL (truly open source). PostgreSQL. Official Helm chart. Extremely extensible
(macros, scripting, apps marketplace). Very stable; 20 years of active development.
Granular page/space permissions.

**Cons:** Java application; heavier than Node.js alternatives (512 MB to 1 GB+ RAM).
Editor is functional but not modern-feeling compared to Notion-style tools.
Structured wiki model (spaces/pages) rather than free-form nesting.
Bitnami chart dependency in transition post-Aug 2025 Docker Hub restriction.

---

### AFFiNE (future watch)

| Attribute | Detail |
|---|---|
| License | MIT |
| OIDC | Supported in self-hosted (admin panel → Settings → OAuth). Broken in v0.25.7 (Dec 2025; issue #14083); unclear if resolved. |
| Database | PostgreSQL only + Redis |
| Kubernetes | **No official Helm chart.** Community chart reported abandoned. Docker Compose is the only officially supported deployment. |
| Editor | Richest feature set; document editor + infinite canvas whiteboard + database/kanban views. |
| Status | Pre-1.0 (v0.26.x as of 2026). 45k+ GitHub stars. Very active. Breaking changes between minor versions. |

**Not ready for this homelab today:** No Kubernetes/Helm support, pre-1.0 stability,
recent OIDC regression. Most compelling long-term option; revisit when a stable Helm
chart ships and OIDC is consistently working.

---

## Eliminated

| Tool | Reason |
|---|---|
| **AppFlowy** | No OIDC support (feature request open, unshipped as of 2026-05) |
| **Siyuan Notes** | No OIDC, no multi-user accounts; personal tool only |
| **DokuWiki** | Flat-file storage (no DB), dated editor, OIDC via third-party plugin only |
| **Docusaurus / MkDocs** | Static site generators; read-only, wrong category |
| **Confluence DC** | Paid enterprise licensing, inappropriate for homelab |

---

## Comparison Matrix

| Tool | License | OIDC free | PostgreSQL | Helm chart | Editor | RAM |
|---|---|---|---|---|---|---|
| Wiki.js v2 | AGPL-3.0 | Yes (native) | Yes | Official | Block + MD | ~200 MB |
| Outline | BSL 1.1 | Yes (mandatory) | Yes | Community | Notion-like | ~300 MB |
| XWiki | LGPL 2.1 | Yes (extension) | Yes | Official | Traditional wiki | ~700 MB |
| AFFiNE | MIT | Yes (buggy) | Yes only | None | Whiteboard+block | ~500 MB |
| Docmost CE | AGPL-3.0 | **No (EE only)** | Yes | Community | Notion-like | ~200 MB |
| BookStack | MIT | **No (SAML only)** | **No (MySQL)** | None | WYSIWYG | ~200 MB |

---

## Decision Drivers

If the concern with Outline is the **license** → **Wiki.js v2** is the clean swap.
Same stack fit (PostgreSQL, Kubernetes, OIDC with Authentik), genuinely OSS, official Helm.
Trade-off: feature-frozen, less polished editor.

If the concern is **editor experience or missing features** → the landscape has no better
option with K8s + OIDC + PostgreSQL today. AFFiNE will eventually be that option.

If the concern is **operational complexity** (no official chart, Redis dependency) →
**Wiki.js v2** again reduces dependencies. XWiki is an alternative if Java resource
usage is acceptable.
