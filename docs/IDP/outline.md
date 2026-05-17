---
title: "Outline — Role and Operational Guide"
type: how-to
status: stable
scope: [k8s]
created: 2026-05-17
updated: 2026-05-17
tags: [outline, wiki, documentation, knowledge-base]
---

# Outline — Role and Operational Guide

**Instance:** `https://outline.kecskemethy.org`
**Login:** Authentik SSO (Authentik credentials; no separate Outline password)
**Namespace:** `outline`

---

## Role in the Documentation Strategy

The homelab uses **two documentation layers** that complement each other:

### Layer 1: Git + Markdown (`docs/` in this repo)

**What goes here:** Technical documentation that lives alongside the code.

- Architecture Decision Records (`docs/adr/`) — decisions and their rationale
- Research notes (`docs/research/`) — evaluations, comparisons, tool selection
- Operational runbooks (`docs/IDP/`, `docs/ansible/`) — how to operate the cluster
- Standards (`docs/STANDARDS.md`) — documentation conventions

**Why Git:** These docs are reviewed like code (PR-gated), version-controlled with the
infrastructure they describe, diff-able, and always in sync with the codebase. When a
runbook changes, it changes in the same commit as the manifest it describes.

**Audience:** Primarily the engineer(s) operating the homelab. Comfortable reading
Markdown in a code editor or on GitHub.

---

### Layer 2: Outline (`outline.kecskemethy.org`)

**What goes here:** Living, collaborative documentation independent of any one codebase.

- **Onboarding guides** for new people to the homelab environment
- **Project notes and working documents** — exploratory ideas not yet committed to a
  decision; meeting notes; in-progress planning that changes daily
- **Process documentation** — recurring workflows, checklists, SOPs that non-engineers
  might reference (e.g. "how to add a user to the homelab")
- **Knowledge that crosses repositories** — content that doesn't belong in any single
  repo's `docs/` folder
- **Rich-content docs** — embeds, diagrams (Draw.io, Mermaid inline), images, tables
  where WYSIWYG editing is faster than Markdown

**Why Outline:** Collaborative editing without a PR; search across all documents; real-time
editing; OIDC-gated so only Authentik users can access it.

---

### Decision Rule: Where Does This Doc Belong?

| Signal | → Git/Markdown | → Outline |
|---|---|---|
| Describes infrastructure configuration | ✅ | |
| Changes with code / should be PR-reviewed | ✅ | |
| Is a decision with lasting architectural weight | ✅ ADR | |
| Is a runbook for cluster operations | ✅ | |
| Is exploratory / in-progress thinking | | ✅ |
| Benefits from real-time collaborative editing | | ✅ |
| Is for a non-developer audience | | ✅ |
| Lives beyond a single repository's lifecycle | | ✅ |
| Would you want a git diff of it? | ✅ | |

**When in doubt:** Start in Git/Markdown. It's always easier to copy to Outline later
than to reconstruct history from Outline.

---

## Operational Notes

### Login

Navigate to `https://outline.kecskemethy.org` and click **Continue with OIDC**.
You will be redirected to Authentik — log in with your homelab credentials.
First login creates your Outline user automatically.

### Backup

Outline data lives in the `outline` PostgreSQL database on the CNPG cluster.
File attachments are stored on a 5 Gi Longhorn PVC (`outline-data`). VolSync backup
for Outline PVC is not yet configured; the database is covered by the CNPG backup
strategy.

### Restart

```bash
kubectl rollout restart deployment/outline -n outline
# Recreate strategy — brief downtime (~10 seconds)
```

### Check Logs

```bash
kubectl logs -n outline deployment/outline --tail=100 -f
```

### Environment / Secrets

Key secrets in `outline` namespace:
- `outline-secret` (SealedSecret) — `SECRET_KEY`, `UTILS_SECRET`
- `outline-db` (SealedSecret) — `DATABASE_URL` (CNPG connection string)
- `outline-oidc` (SealedSecret) — `OIDC_CLIENT_SECRET`

To rotate `SECRET_KEY` or `UTILS_SECRET`: generate new random values
(`openssl rand -hex 32`), re-seal, commit, and restart. Rotating these invalidates
all active Outline sessions.

---

## Planned

- VolSync daily backup for the `outline-data` PVC → restic REST server
- Garage S3 for file attachment storage (replace `FILE_STORAGE: local`)
- Pin Outline to a specific version tag instead of `latest`
