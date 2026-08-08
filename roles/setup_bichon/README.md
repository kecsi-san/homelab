# setup_bichon

> **Status: Planned**: placeholder only, not yet implemented.

Deploys [Bichon](https://github.com/rustmailer/bichon): a self-hosted email archive with full-text search, built in Rust with a React web UI.

## What it does

- Deploys Bichon as a Docker container (or single binary)
- Connects to Dovecot via IMAP pull for incremental archiving
- Optionally wires Postfix `always_bcc` to Bichon's embedded SMTP receiver for MTA-level capture
- Exposes web UI behind a reverse proxy

## Why Bichon

Chosen over alternatives (Piler, Mail-Archiver, OpenArchiver) for:
- Single binary / minimal dependencies (no separate DB required)
- Rust; low memory footprint, suitable for the existing EC2 instance
- Modern React UI with threaded view and full-text search (Tantivy)
- AGPL-3.0 license
- Actively maintained (1,800+ stars, released June 2026)

See [`docs/research/email-archive-software.md`](../../docs/research/email-archive-software.md) for the full evaluation.

## Variables

| Variable | Default | Description |
|---|---|---|
| `bichon_version` | `latest` | Docker image tag |
| `bichon_port` | `8080` | Web UI listen port |
| `bichon_imap_host` | `localhost` | IMAP server to pull from |
| `bichon_imap_port` | `993` | IMAP port |
| `bichon_data_dir` | `/var/lib/bichon` | Persistent data directory |

## Dependencies

- Dovecot IMAP running (see `setup_email-server`)
- A reverse proxy for HTTPS (Apache or nginx)

## Notes

- IMAP pull is the primary ingestion method; archives existing mailboxes incrementally
- For MTA-level capture (outbound + mail that never hits a mailbox), also set `always_bcc` in Postfix pointing to Bichon's embedded SMTP on port 2525
