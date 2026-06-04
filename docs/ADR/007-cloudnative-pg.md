---
title: "007 — CloudNativePG for PostgreSQL"
type: adr
status: accepted
scope: [k8s, k3s]
created: 2026-05-10
updated: 2026-05-17
tags: [postgresql, cnpg, database, operator]
---

# 007 — CloudNativePG for PostgreSQL

## Status

Accepted

## Context

Multiple IDP components require PostgreSQL: Forgejo, Authentik, Outline, and the
planned Backstage. The homelab had two options: deploy a single shared PostgreSQL
instance per-namespace (simple but brittle), or use a Kubernetes operator that
manages PostgreSQL clusters as native k8s resources.

Requirements:
- Shared cluster serving multiple databases with per-app users
- Managed credentials (no manual password rotation, k8s Secrets integration)
- HA capability (multiple replicas with streaming replication) for k8s
- Minimal footprint for k3s (single instance acceptable)
- Operator-managed backups and point-in-time recovery capability
- Standard PostgreSQL (not a fork or proprietary wrapper)

## Decision

Use **CloudNativePG (CNPG)** operator with a single `Cluster` CR per cluster:

- **k8s**: `postgres` namespace, 3-instance cluster (1 primary + 2 replicas),
  2 Gi Longhorn PVCs per instance
- **k3s**: `postgres` namespace, 1-instance cluster, 2 Gi local-path PVC

Databases and users provisioned via:
- `managed.roles[]` in `Cluster` spec: creates PostgreSQL roles with k8s Secrets
- `Database` CR: declares databases with owner reference
- App-specific SealedSecrets hold the credentials; apps reference them directly

Key operational note: `ServerSideApply=true` required in ArgoCD (CNPG CRDs exceed the
262 KB `kubectl apply` annotation limit). `ignoreDifferences` on `terminatingReplicas`
field to prevent ArgoCD drift detection false positives.

## Alternatives Considered

| Option | Reason rejected |
|---|---|
| **Standalone PostgreSQL Deployment** | No streaming replication; no operator-managed failover; credentials managed entirely manually; no `Database` or `Role` CRs — everything done via `psql` by hand |
| **Zalando postgres-operator** | Older, less active maintenance; Patroni-based (adds complexity); `CRD` model is less ergonomic than CNPG's; CNPG has become the community standard since CNCF incubation |
| **CrunchyData PGO** | Enterprise-focused, complex; PGO v5 requires a significant learning investment; the community edition has limitations; overkill for a homelab |
| **Bitnami PostgreSQL Helm chart** | StatefulSet without an operator; no `Database` or `Role` CRs; backups require manual configuration; no automated failover |
| **Per-app PostgreSQL** | One StatefulSet per application; simpler per-app but wasteful (each app gets its own Postgres process, PVC, and replica count); harder to manage credentials centrally |

## Consequences

**Positive:**
- `Database` and `Role` CRs enable declarative database provisioning — adding a new
  application database is a 20-line manifest, not a `psql` session
- Streaming replication on k8s (3 instances) provides read scalability and automatic
  failover if the primary fails
- CNPG's `kubectl cnpg` plugin and `psql` access via `kubectl exec` (peer auth on the
  primary) make debugging straightforward (see `docs/IDP/postgres.md`)
- CNPG is CNCF Incubating (as of 2024); strong community, EDB-backed; long-term
  sustainability confidence
- WAL archiving and PITR (point-in-time recovery) are available when a backup target
  is configured; not yet configured on this homelab but the infrastructure is ready

**Negative / Trade-offs:**
- `ServerSideApply=true` in ArgoCD is a cluster-wide setting for the CNPG app; it
  changes how ArgoCD applies all CNPG manifests, which can cause unexpected behavior
  if not understood
- `ignoreDifferences` for `terminatingReplicas` is a workaround for CNPG's internal
  state management — if CNPG changes this field's semantics, the ignore rule may mask
  real drift
- Superuser access requires `kubectl exec` into the primary pod (peer auth, no password);
  there is no external superuser endpoint — all admin work goes through the pod
- App credentials stored in SealedSecrets per namespace: sealing must happen against
  the correct cluster context; a k3s-sealed secret will not decrypt on k8s
