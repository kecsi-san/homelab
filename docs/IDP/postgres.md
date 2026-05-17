---
title: "PostgreSQL Access (CNPG)"
type: how-to
status: stable
scope: [k8s]
created: 2026-05-16
updated: 2026-05-16
tags: [postgresql, cnpg, database, runbook]
---

# PostgreSQL Access (CNPG)

CNPG manages a 3-instance PostgreSQL 17 cluster (`postgres`) in the `postgres` namespace.
The primary is always reachable at `postgres-rw.postgres.svc.cluster.local:5432`.

## Connect as superuser

Peer auth is enabled inside the pod — no password required:

```bash
kubectl exec -it -n postgres postgres-1 -- psql -U postgres
```

Replace `postgres-1` with `postgres-2` or `postgres-3` if needed;
`postgres-1` is normally the primary.

## Common psql commands

| Command | Purpose |
|---------|---------|
| `\l` | List databases |
| `\du` | List roles |
| `\c <db>` | Connect to a database |
| `\dt` | List tables in current database |
| `\q` | Quit |

## Current databases

| Database | Owner | Purpose |
|----------|-------|---------|
| `forgejo` | forgejo | Forgejo git server |
| `authentik` | authentik | Authentik IdP |
| `docmost` | docmost | Docmost wiki |

## Connect as an app user

App passwords are stored as SealedSecrets in the `postgres` namespace.
Decode a password on the fly and open a session:

```bash
# Example: connect as the forgejo user
PGPASS=$(kubectl get secret forgejo-db-credentials -n postgres \
  -o jsonpath='{.data.password}' | base64 -d)

kubectl run psql-tmp --rm -it --restart=Never \
  --image=postgres:17-alpine \
  --env="PGPASSWORD=${PGPASS}" \
  -- psql -h postgres-rw.postgres.svc.cluster.local -U forgejo -d forgejo
```

Swap `forgejo-db-credentials` / `forgejo` / `forgejo` for
`authentik-db-credentials` / `authentik` / `authentik`
or `docmost-db-credentials` / `docmost` / `docmost` as needed.

## Services

| Service | Purpose |
|---------|---------|
| `postgres-rw` | Primary (read-write) |
| `postgres-ro` | Replicas (read-only, load-balanced) |
| `postgres-r` | All instances (read, load-balanced) |

## Install the cnpg kubectl plugin (optional)

The plugin adds convenience commands like `kubectl cnpg psql`, `kubectl cnpg status`:

```bash
# Via krew
kubectl krew install cnpg
```
