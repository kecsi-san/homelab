---
title: "Email Archive Software Survey"
type: research
status: done
scope: [email, aws-ec2]
created: 2026-06-11
tags: [email, archiving, postfix, dovecot, self-hosted]
---

# Email Archive Software Survey

Research into self-hosted email archiving solutions for a personal/small-business email server running Postfix + Dovecot (1–10 users).

## Summary

| Tool | Stack | Integration | License | Stars | Last Release | Effort |
|---|---|---|---|---|---|---|
| **Piler** | PHP/C | BCC → embedded SMTP | GPL-3.0 | 323 | Sep 2025 | High |
| **Bichon** | Rust | IMAP pull or BCC → embedded SMTP | AGPL-3.0 | 1,800 | Jun 2026 | Low |
| **OpenArchiver** | TS/Node | IMAP pull | AGPL-3.0 | 2,100 | Mar 2026 | Medium |
| **Mail-Archiver** | C#/.NET 8 | IMAP pull | GPL-3.0 | 1,900 | Jun 2026 | Low |
| **MailArchiva** | Java | BCC → embedded SMTP | Commercial (free ≤9) | — | Active | Medium |
| **Postfix BCC → Maildir** | none | native Postfix | — | — | — | Minimal |

## Decision

**Chosen: Bichon** — lightweight single binary, Rust, AGPL-3.0, IMAP pull from Dovecot, modern React UI, actively maintained. Ansible role placeholder created (`setup_bichon`).

---

## Dedicated Archive Tools

### Piler (mailpiler)

- **Stack:** PHP (core), C (indexer), MySQL/MariaDB + Sphinx/Manticore search
- **Integration:** BCC via Postfix `always_bcc` / `sender_bcc_maps` + `recipient_bcc_maps`. Piler runs its own embedded SMTP listener; Postfix drops a copy there. Milter option exists but discouraged (milter failure blocks delivery).
- **Web UI:** Full-featured — search, tagging, audit trails, LDAP/AD/SSO/IMAP/Google OAuth login, 2FA, admin console. Looks dated but functional.
- **License:** GNU GPL-3.0
- **Status:** Active. v1.4.8 — September 2025. 323 GitHub stars, 2,100+ commits.
- **Notes:** Most "enterprise-style" open source option. Well-documented Postfix BCC integration. Non-trivial setup. GoBD/compliance use cases. Best fit when MTA-level capture is required (every message, even those that never reach a mailbox).

### Bichon

- **Stack:** Rust (backend + embedded SMTP), React/TypeScript (web UI), Tantivy (full-text search)
- **Integration:** Primarily IMAP pull (UID-based incremental sync). Also exposes an embedded SMTP receiver (port 2525 by default) for Postfix BCC. No milter.
- **Web UI:** Clean modern React UI — threaded message view, tagging, attachment downloads, analytics dashboard.
- **License:** AGPL-3.0
- **Status:** Very active. v1.5.2 — June 2026. 1,800 GitHub stars, 61 forks.
- **Notes:** Single binary or Docker. Optional at-rest encryption. Zero telemetry. Best fit for personal/small-team use against an existing Dovecot IMAP server.
- **Links:** https://github.com/rustmailer/bichon

### OpenArchiver

- **Stack:** TypeScript/Node.js (Express) backend, SvelteKit 5 frontend, PostgreSQL, Meilisearch, Redis/Valkey
- **Integration:** IMAP pull only. Supports Google Workspace, M365, any IMAP inbox, PST/MBOX import.
- **Web UI:** Modern SvelteKit UI — dashboard, full-text search across emails and attachments via Meilisearch, inline image display.
- **License:** AGPL-3.0
- **Status:** Active. v0.5.0 — March 2026. 2,100 GitHub stars.
- **Notes:** Heaviest dependency footprint (Postgres + Meilisearch + Redis). Stores emails as .eml files. Community reports slower archiving performance. Good for eDiscovery use cases.
- **Links:** https://github.com/LogicLabs-OU/OpenArchiver

### Mail-Archiver

- **Stack:** C#/.NET 8 (ASP.NET Core MVC), Bootstrap UI, PostgreSQL
- **Integration:** IMAP pull + M365 Graph API.
- **Web UI:** Responsive Bootstrap interface — search by sender/subject/date, batch MBOX/EML export, retention policies, multi-user permissions, storage dashboard.
- **License:** GPL-3.0
- **Status:** Very active. v2606.1 — June 2026. 1,900 GitHub stars, 48 releases.
- **Notes:** No attachment full-text search (known limitation). Fastest IMAP archiver tested in Cloudron community benchmarks. Requires reverse proxy for HTTPS. .NET runtime on Linux.
- **Links:** https://github.com/s1t5/mail-archiver

### MailArchiva

- **Stack:** Java
- **Integration:** Postfix BCC (SMTP to embedded listener). Free tier: up to 9 mailboxes.
- **License:** Commercial (proprietary)
- **Status:** Active commercial product.
- **Notes:** Polished solution, but proprietary. The "open source edition" on GitHub is an old unmaintained fork.

---

## DIY Approaches

### Postfix `always_bcc`

```
always_bcc = archive@yourdomain.com
```

Every message (in and out) gets a blind copy to a local archive mailbox. Access via Dovecot IMAP + FTS. Zero extra software, zero maintenance overhead. No deduplication, no audit UI, no retention policies. Frequently recommended on r/selfhosted for personal use.

### Dovecot Sieve `fileinto`

Server-side Sieve rule copies all delivered mail into a date-structured Archive folder tree. Works for inbound only (outgoing requires Postfix BCC loop-back). Zero extra software, browseable via any IMAP client.

### notmuch + mbsync

Pull all mail via IMAP to local Maildirs, index with notmuch for full-text search. CLI-centric, no web UI. Popular in homelab/sysadmin circles for personal use.

---

## What People Actually Use

Based on Cloudron forum threads, HN, and r/selfhosted:

- **Compliance / audit trail (small businesses, GoBD):** Piler — only mature BCC-integrated archive with years of production use.
- **Personal archiving / "I just want search":** Bichon and Mail-Archiver gaining fast adoption in 2025–2026; easy Docker deployment, clean UIs, both work against Dovecot IMAP.
- **Truly minimal:** Postfix `always_bcc` to a local mailbox — most common r/selfhosted answer; no extra service, zero maintenance.
- **MailStore Home** (Windows-only, free, excellent full-text including attachments) is the community "gold standard" but irrelevant for Linux-native setups.
