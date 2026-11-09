---
title: "Forgejo: Operational Guide"
type: how-to
status: stable
scope: [k8s]
created: 2026-05-17
updated: 2026-05-17
tags: [forgejo, git, ci-cd, oci-registry, tea-cli, runners, mirrors]
---

# Forgejo: Operational Guide

**Instance:** `https://forgejo.kecskemethy.org`
**Admin user:** `kecsi`
**Namespace:** `forgejo`

---

## tea CLI Setup

`tea` is Forgejo's (and Gitea's) official CLI for repository management, issue
tracking, and API interactions.

### Install

```bash
# Via Homebrew (installed by setup_kube-extra role)
brew install tea

# Or directly
curl -fsSL https://dl.gitea.com/tea/main/tea-main-linux-amd64 -o ~/.local/bin/tea
chmod +x ~/.local/bin/tea
```

### Login

```bash
tea login add \
  --name homelab \
  --url https://forgejo.kecskemethy.org \
  --token <your-api-token>

# Generate token at: https://forgejo.kecskemethy.org/user/settings/applications
# Grant: issue, notification, organization, package, repository, user scopes

# Verify
tea login list
```

### Common Commands

```bash
# List your repos
tea repo list

# Create a new repository
tea repo create --name my-repo --description "My repo" --private

# List open issues in a repo
tea issue list --repo kecsi/my-repo

# Create a release
tea release create --repo kecsi/my-repo --tag v1.0.0 --title "v1.0.0"

# List workflow runs (Actions)
tea actions list --repo kecsi/my-repo

# Switch the default login / remote
tea login default homelab
```

---

## OCI Container Registry

Forgejo's built-in package registry supports OCI images at:
`forgejo.kecskemethy.org/<username>/<repo>:<tag>`

### Push an Image

```bash
# Login to the registry (use an API token, not your password)
docker login forgejo.kecskemethy.org \
  --username kecsi \
  --password <api-token>

# Tag and push
docker tag myimage:latest forgejo.kecskemethy.org/kecsi/myimage:latest
docker push forgejo.kecskemethy.org/kecsi/myimage:latest
```

### Pull an Image

```bash
docker pull forgejo.kecskemethy.org/kecsi/myimage:latest
```

### In Forgejo Actions (CI)

```yaml
- name: Log in to Forgejo registry
  uses: docker/login-action@v3
  with:
    registry: forgejo.kecskemethy.org
    username: ${{ secrets.FORGEJO_ACTOR }}
    password: ${{ secrets.FORGEJO_TOKEN }}

- name: Build and push
  uses: docker/build-push-action@v5
  with:
    push: true
    tags: forgejo.kecskemethy.org/kecsi/${{ github.repository }}:${{ github.sha }}
```

Registry browsing: `https://forgejo.kecskemethy.org/kecsi/-/packages`

---

## CI Runners (Forgejo Actions)

### Runner Status

```bash
# Via Forgejo admin UI
open https://forgejo.kecskemethy.org/-/admin/runners

# Via kubectl (in-cluster runner)
kubectl get pods -n forgejo-runner
kubectl logs -n forgejo-runner deployment/forgejo-runner -c runner
```

### Runner Registration

The k8s runner is registered once (on first pod start) and persists via a Longhorn
PVC. The registration init container checks for `/data/.runner` before attempting
registration, so restarts are safe.

To force re-registration (e.g. after a token rotation):

```bash
# Delete the .runner file to trigger re-registration on next pod start
kubectl exec -n forgejo-runner deployment/forgejo-runner -c runner -- \
  rm /data/.runner
kubectl rollout restart deployment/forgejo-runner -n forgejo-runner
```

Get a new runner token: `https://forgejo.kecskemethy.org/-/admin/runners` → Create new Runner.

### Runner Labels

The current runner accepts jobs with:
- `runs-on: ubuntu-latest` → container image `node:20-bookworm`
- `runs-on: self-hosted` → same

To add a custom label (e.g. for Python workflows):

```yaml
# In forgejo-runner configmap.yaml labels section, add:
python-3.12:docker://python:3.12-slim
```

Then re-register the runner (delete `.runner` and restart).

### Offline / Duplicate Runner Cleanup

After failed restarts (pre-PVC persistence), stale offline runners accumulate.
Delete them at `https://forgejo.kecskemethy.org/-/admin/runners`, click each
offline runner → Delete.

---

## Admin Tasks

### Access the Admin Panel

`https://forgejo.kecskemethy.org/-/admin/`. Requires login as `kecsi`.

### Database Access

```bash
# Forgejo uses the 'forgejo' database on the CNPG cluster
kubectl exec -n postgres -it \
  $(kubectl get pods -n postgres -l cnpg.io/instanceRole=primary -o name | head -1) \
  -- psql -U forgejo -d forgejo
```

### Restart Forgejo

```bash
kubectl rollout restart deployment/forgejo -n forgejo
# Note: Recreate strategy: brief downtime (~15 seconds) during restart
```

### Check Logs

```bash
kubectl logs -n forgejo deployment/forgejo --tail=100 -f
```

### Update Forgejo Version

The image tag is pinned to an exact patch release (for example `15.0.11-rootless`), not a floating major tag.
Forgejo can't be downgraded once the database migrates, so before changing it:

1. Back up the database (`pg_dump -Fc` from the CNPG primary) and the `forgejo-data` volume. Neither is covered by VolSync or CNPG backups.
2. Run `forgejo manager flush-queues` in the pod.
3. Read the breaking changes for every major you cross. A direct jump from 10.0.x to a later major is supported, but each release lists config changes (the upgrade guide is at `forgejo.org/docs/latest/admin/upgrade/`).

Then edit the image tag in `kube-gitops/k8s/forgejo/deployment.yaml` and `job-register-authentik.yaml`.
ArgoCD applies the change on the next sync. The `Recreate` strategy ensures no two pods hold the LevelDB queue lock
simultaneously. Rolling back means restoring the backup.

Stay on the LTS line (15.0.x until July 2027) unless a feature from a newer release is needed; the next LTS is 19.0 in April 2027.

---

## Webhook → ArgoCD Sync

Forgejo can trigger an immediate ArgoCD sync on push rather than waiting for the
3-minute ArgoCD poll interval.

Configure at: `https://forgejo.kecskemethy.org/kecsi/homelab/settings/hooks`

Note: the homelab GitOps repo is on GitHub, not Forgejo. This webhook applies to
internal repos that ArgoCD may read from in the future.

For the GitHub-sourced homelab repo, configure the webhook in GitHub:
`Settings → Webhooks → Add webhook`
URL: `https://argocd.kecskemethy.org/api/webhook`

---

## Forgejo Organisations

| Org | Purpose |
|-----|---------|
| `homelab` | Shared templates and internal tools used across projects |
| `mirrors` | Read-only mirrors of upstream GitHub Actions for offline CI use |
| `kecsi` | Personal repositories and experiments |

### mirrors org: Action Mirrors

Forgejo Actions workflows reference actions via full URL
(`https://forgejo.kecskemethy.org/mirrors/<name>@<ref>`) instead of the GitHub
shorthand (`actions/checkout@v4`). Each mirror is a Forgejo-managed periodic sync
from the upstream GitHub repo.

| Mirror repo | Upstream GitHub source | Used for |
|-------------|------------------------|----------|
| `mirrors/checkout` | `actions/checkout` | Repo checkout in every workflow |
| `mirrors/cache` | `actions/cache` | Dependency caching (pre-commit, uv) |
| `mirrors/setup-python` | `actions/setup-python` | Python version management |
| `mirrors/setup-uv` | `astral-sh/setup-uv` | uv installation + cache |
| `mirrors/upload-artifact` | `actions/upload-artifact` | Artifact passing between jobs |
| `mirrors/download-artifact` | `actions/download-artifact` | Artifact passing between jobs |
| `mirrors/codecov-action` | `codecov/codecov-action` | Coverage upload (available but not wired) |

To add a new mirror: Forgejo UI → `+` → Migrate repository → Git → paste GitHub URL →
set owner to `mirrors` → enable "This repository will be a mirror".

---

## Planned

- **SSH access**: Forgejo SSH (port 22) not yet exposed; needs a separate TCP
  LoadBalancer service or Traefik TCP entrypoint; currently using HTTPS + credential store
- **Semgrep OSS + Trivy**: as CI pipeline steps; see [CI Pipelines](ci-pipelines.md)
- **CD pipeline**: push-to-main triggers ArgoCD sync via webhook; covered once
  the first Python project is in use
- **Forgejo LFS → Garage S3**: `forgejo` bucket on the existing Garage instance;
  avoids large file storage on Longhorn PVC
