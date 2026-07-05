---
title: "Secret Store Comparison — HashiCorp Vault vs OpenBao"
type: research
status: stable
scope: [general, ansible]
created: 2026-07-05
updated: 2026-07-05
tags: [secrets, vault, openbao, comparison]
---

# Secret Store Comparison — HashiCorp Vault vs OpenBao

Research done ahead of migrating EC2/Ansible secrets (see `docs/howtos/vault-secrets-architecture.md`)
out of `secrets.yml` and into a real secret store, to confirm HashiCorp Vault — already
live at `vault.kecskemethy.hu` since Phase 4 of the EC2 rebuild — is still the right choice
rather than starting over on OpenBao.

---

## TL;DR — Recommendation

**Continue with the already-deployed Vault instance.** No homelab-specific reason surfaced
to justify redoing the install/init/unseal work under OpenBao. The BSL license terms that
motivated OpenBao's creation don't practically apply to internal/personal use, and OpenBao's
Vault-compatible API means a future switch stays realistic if the governance angle ever
matters enough on its own.

| Factor | Vault | OpenBao | Matters here? |
|---|---|---|---|
| Already deployed | ✅ live since 2026-07-04 | ❌ would need fresh install/init/unseal | Yes — avoids redoing completed work |
| License | BSL 1.1 (2023–) | MPL 2.0 (Linux Foundation/OpenSSF) | Only if commercially competing with HashiCorp — not this use case |
| Feature parity for homelab use | Full (KV, PKI, dynamic DB creds, AppRole/userpass, K8s Agent injection) | Same, plus free Namespaces (Vault Enterprise-only) | No — single-node homelab doesn't need Namespaces or Enterprise Replication either way |
| GitHub stars (ecosystem proxy) | ~35.9k (since 2015) | ~5.4k (forked 2024) | Larger existing Terraform/Ansible tooling and community troubleshooting content for Vault |
| Operator familiarity | Already known | Would need to learn | Yes — directly reduces migration risk |
| Future switch cost | — | Low (API/storage-compatible fork) | Keeps the door open without needing to plan for it now |

---

## Context

No prior comparison existed in this repo before this doc — checked `docs/research/` (home
to similar surveys like `homelab-idp-components.md`) and found nothing; the only mention
anywhere was a passing "(or OpenBao)" aside in `TODO.md`'s Big Migrations section.

## Findings

**Governance and licensing.** HashiCorp relicensed Vault from MPL 2.0 to Business Source
License (BSL) 1.1 in 2023. BSL restricts *commercially competing* with HashiCorp's own
hosted Vault offering — it does not restrict internal or personal use, which is all this
repo needs. OpenBao is the community fork (Linux Foundation, OpenSSF-hosted) taken from
Vault 1.14.0, the last MPL-licensed release, and remains MPL 2.0 with open governance
(any contributor participates on equal footing, unlike HashiCorp's corporate governance
of Vault).

**Feature parity.** For standard secrets-management use — KV v2, PKI issuance, dynamic
database credentials, AppRole/userpass auth, Kubernetes Agent sidecar injection — the two
are functionally equivalent. OpenBao includes Namespaces (multi-tenant administrative
isolation) for free, which is Vault Enterprise-only; Vault Enterprise in turn retains
Performance/Disaster-Recovery Replication and Sentinel policy-as-code, neither of which
OpenBao has. None of this — Namespaces, Replication, Sentinel — is relevant to a
single-node, single-admin homelab.

**Ecosystem maturity.** Vault has roughly 35.9k GitHub stars and a decade of production
use (since 2015); OpenBao has roughly 5.4k stars, having forked in 2024. In practice this
means far more existing Terraform provider coverage, Ansible collection maturity, and
community troubleshooting content (Stack Overflow, blog posts) for Vault. OpenBao
deliberately preserves Vault's API and on-disk storage format, so tooling built against
Vault mostly works unmodified against OpenBao, and a migration between the two is more
tractable than a typical platform swap if ever wanted later.

**No strong homelab-specific consensus.** General web search turned up mostly
enterprise/platform-team-oriented comparisons (Digitalis, Jorijn Schrijvershof, wetheflywheel);
none surfaced a homelab-community-specific groundswell toward either project. The
consistent theme across sources: choose based on licensing philosophy, not technical
differentiation, since the technical differentiation barely exists for standard use.

## Decision

Continue with HashiCorp Vault for the EC2/Ansible secrets migration. Revisit only if the
BSL license terms become a genuine practical concern (e.g. wanting to offer a hosted Vault
service commercially, which is not a homelab scenario) or if OpenBao's ecosystem grows to
clear parity — at which point the migration cost is expected to be low given API
compatibility.

## Sources

- [Choosing a secrets storage: HashiCorp Vault vs OpenBao — Digitalis](https://digitalis.io/post/choosing-a-secrets-storage-hashicorp-vault-vs-openbao)
- [HashiCorp Vault vs OpenBao: a thorough comparison for platform teams — Jorijn Schrijvershof](https://jorijn.com/en/blog/hashicorp-vault-vs-openbao/)
- [OpenBao vs HashiCorp Vault: the Open-Source Fork, Compared — wetheflywheel](https://wetheflywheel.com/en/comparisons/openbao-vs-hashicorp-vault/)
- [OpenBao project site](https://openbao.org/)
- [hashicorp/vault on GitHub](https://github.com/hashicorp/vault)
