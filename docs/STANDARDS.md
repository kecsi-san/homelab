---
title: "Documentation Standards"
type: reference
status: stable
scope: [general]
created: 2026-05-17
updated: 2026-05-17
tags: [meta, documentation, standards]
---

# Documentation Standards

This document defines the documentation standard for the homelab repository. Every file
under `docs/` follows these conventions so that docs remain navigable, searchable, and
useful over time — especially when imported into Outline or rendered by a static site
generator.

---

## Framework: Diátaxis

We follow the [Diátaxis](https://diataxis.fr) documentation framework. It organizes
documentation by purpose into four types:

| Type | Oriented toward | Answers the question | Examples |
|---|---|---|---|
| **how-to** | Action | "How do I accomplish X?" | Runbooks, operational procedures |
| **reference** | Information | "What is the current state/spec of X?" | Status docs, config references |
| **research** (explanation) | Understanding | "Why does X work this way? What are the options?" | Tech comparisons, architecture rationale |
| **adr** | Decision | "Why did we make this decision?" | Architecture Decision Records |

A fifth type, **tutorial**, would cover guided learning (e.g. "first-time cluster setup
walkthrough"). We do not have tutorials yet; add them under `docs/tutorials/` when needed.

### Practical classification guide

- Procedure someone follows step-by-step → **how-to**
- Current state of a system, list of options, config spec → **reference**
- Evaluation of tools, comparison of approaches, rationale → **research**
- A specific decision that is hard to reverse and worth justifying → **adr**
- Mixed? Pick the dominant purpose. Split into two docs if genuinely 50/50.

---

## Front-matter Specification

Every document starts with a YAML front-matter block. All fields are required.

```yaml
---
title: "Full Human-Readable Title"
type: how-to | reference | research | adr | tutorial
status: draft | stable | deprecated
scope: [general | k8s | k3s | ansible | idp]   # one or more
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: [tag1, tag2]                              # at least one
---
```

### Field reference

| Field | Values | Notes |
|---|---|---|
| `title` | string | Full title; matches the H1 heading below |
| `type` | `how-to` `reference` `research` `adr` `tutorial` | See Diátaxis above |
| `status` | `draft` `stable` `deprecated` | `draft` = work in progress; `stable` = accurate; `deprecated` = superseded or no longer applicable |
| `scope` | `general` `k8s` `k3s` `ansible` `idp` | Which systems/layers this applies to; list if multiple |
| `created` | `YYYY-MM-DD` | Date the file was first committed (check `git log`) |
| `updated` | `YYYY-MM-DD` | Date of last meaningful content change |
| `tags` | list of strings | Free-form; use lowercase, hyphens; minimum one |

### Status semantics

- **draft** — being written or not yet verified against a running system; do not rely on it
- **stable** — accurate as of `updated` date; verified against a running system or confirmed by review
- **deprecated** — the information is outdated, superseded, or the system no longer exists;
  add a note at the top pointing to the replacement

---

## Folder Structure

```
docs/
├── STANDARDS.md          ← this file
├── README.md             ← index and nav guide
├── adr/                  ← Architecture Decision Records
├── ansible/              ← how-to + reference docs for Ansible roles and playbooks
├── IDP/                  ← how-to + reference + research docs for the IDP stack
├── research/             ← research (explanation) docs: tech comparisons, evaluations
└── tutorials/            ← (future) guided walkthroughs for new team members
```

**Why topic folders rather than type folders?**
Grouping by system (IDP, ansible) rather than by type (how-to, reference) makes navigation
faster when you know *what system* you are working on. The `type` field in front-matter
provides the type dimension for search and tooling.

---

## Document Structure

After the front-matter block, every document follows this layout:

```markdown
---
[front-matter]
---

# Title

One-sentence description of what this document covers and who it is for.

---

[content]
```

### Headings

- `#` (H1) — document title only; one per file; matches `title` in front-matter
- `##` (H2) — major sections
- `###` (H3) — sub-sections
- `####` (H4) — use sparingly; prefer restructuring over deep nesting

### Tables

Prefer tables over long bulleted lists for structured data (comparisons, configs, options).
Include a header row. Align columns with spaces for readability in raw markdown.

### Code blocks

Always specify the language for syntax highlighting:

````markdown
```bash
kubectl get pods -n argocd
```

```yaml
apiVersion: v1
kind: ConfigMap
```
````

### Links

- Use relative paths for internal links: `[Status](../IDP/status.md)`
- Use full URLs for external references

---

## Architecture Decision Records (ADRs)

Use the ADR format when a decision is:
- Hard to reverse (e.g. storage backend, cluster topology, IdP product)
- Worth explaining to future-you or a new contributor
- The result of evaluating multiple options

Store ADRs in `docs/adr/` with the naming convention `NNN-short-title.md`
(e.g. `001-authentik-over-keycloak.md`).

### ADR template

```markdown
---
title: "NNN — Short title"
type: adr
status: accepted | proposed | deprecated | superseded-by NNN
scope: [...]
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: [...]
---

# NNN — Short title

## Status

Accepted / Proposed / Deprecated / Superseded by [NNN](NNN-title.md)

## Context

What situation or requirement prompted this decision?
What constraints exist (cost, skills, compatibility, licence)?

## Decision

What did we decide to do? One clear statement.

## Alternatives Considered

| Option | Reason rejected |
|---|---|
| Option A | ... |
| Option B | ... |

## Consequences

What becomes easier or harder as a result of this decision?
What follow-up decisions does this create?
```

---

## Update Process

- **Update `updated:` date** whenever you make a meaningful content change (not typo fixes).
- **Do not update `created:`** — it records the origin date.
- If a doc becomes inaccurate but you cannot update it immediately, change `status: draft`
  and add a `> ⚠ Under revision — content may be outdated.` blockquote at the top.
- When a doc is fully superseded, change `status: deprecated`, add a note at the top
  pointing to the replacement, and do not delete the file (history is useful).

---

## What Not to Document

- **Code comments** — inline code explains *what*; docs explain *why* and *how* at system
  level. Do not duplicate what the code already says.
- **Transient state** — do not document "current sprint tasks" or "TODO this week" in docs
  files; those live in issues or the conversation.
- **Git history** — who changed what and when is in `git log`. Do not replicate it in docs.

---

## Considered and Rejected

### Johnny Decimal

Johnny Decimal is a numbering system for personal file organization (e.g. `10-19 IDP/`,
`10.01 Authentik/`). It works well for managing unstructured personal files (email,
documents, bookmarks) but adds friction to a git repository where folder names are already
self-documenting and search (`grep`, `find`, IDE search) is fast. Not adopted.

### Badges (shields.io)

SVG badges embedded in markdown (![stable](https://img.shields.io/...)) add visual
interest to README files but become noise inside a docs folder. The `status:` front-matter
field provides the same information in a machine-readable form. Not adopted.
