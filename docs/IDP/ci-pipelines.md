---
title: "CI Pipelines — Forgejo Actions"
type: how-to
status: stable
scope: [k8s]
created: 2026-05-17
updated: 2026-05-17
tags: [forgejo, ci-cd, actions, python, cookiecutter, semgrep, trivy]
---

# CI Pipelines — Forgejo Actions

Forgejo Actions uses GitHub Actions-compatible YAML syntax. Workflows live in
`.forgejo/workflows/` (not `.github/workflows/`). The in-cluster runner picks up
jobs tagged `ubuntu-latest` or `self-hosted` and executes steps inside Docker
containers via DinD.

---

## Python Project Template

### Template source

`homelab/cookiecutter-uv` — a Forgejo-adapted fork of
[osprey-oss/cookiecutter-uv](https://github.com/osprey-oss/cookiecutter-uv).

**Adaptations made from upstream:**
- `.github/` renamed to `.forgejo/` at both the template repo level and inside
  the generated project (`{{cookiecutter.project_name}}/.forgejo/`)
- All GitHub action references replaced with Forgejo mirror URLs:
  `actions/checkout@v4` → `https://forgejo.kecskemethy.org/mirrors/checkout@v4` etc.
- Codecov upload step removed (not in use)
- `validate-codecov-config.yml` removed from generated template
- GitHub Pages `deploy-docs` job removed from `on-release-main.yml`
  (GitHub Pages is not available on Forgejo; docs publishing via Forgejo Pages or
  MkDocs to a static host is a future option)
- `on-release-main.yml` retained for optional PyPI or Forgejo package registry publish

### Generate a new project

```bash
uvx cookiecutter https://forgejo.kecskemethy.org/homelab/cookiecutter-uv.git
```

**Recommended answers for internal homelab tooling:**

| Prompt | Answer | Notes |
|--------|--------|-------|
| `project_name` | your project name | e.g. `my-tool` |
| `project_slug` | auto-derived | Python package name |
| `layout` | `src` | src layout; PA recommendation |
| `include_github_actions` | `y` | generates `.forgejo/workflows/` |
| `publish_to_pypi` | `n` | internal tools; no PyPI publish |
| `deptry` | `y` | catches missing/unused deps at build time |
| `docs_tool` | `mkdocs` | MkDocs Material |
| `codecov` | `n` | not in use |
| `dockerfile` | `y` | needed for k8s deployment |
| `devcontainer` | `y` | reproducible dev environment |
| `type_checker` | `mypy` | switch to `ty` once it exits alpha |
| `open_source_license` | `Not open source` | internal tools |

### Generated CI workflow structure

After generation, `.forgejo/workflows/main.yml` runs three parallel jobs on every
push to `main` and every PR:

```
main.yml
├── quality          runs-on: ubuntu-latest
│   ├── checkout
│   ├── cache pre-commit
│   ├── setup-python-env (composite action)
│   └── make check   (pre-commit + deptry + uv lock check)
│
├── tests-and-type-check   matrix: python 3.10–3.14
│   ├── checkout
│   ├── setup-python-env
│   ├── pytest (+ coverage if codecov=y)
│   └── mypy (or ty check)
│
└── check-docs       (if docs_tool = mkdocs or zensical)
    ├── checkout
    ├── setup-python-env
    └── mkdocs build -s
```

The composite action (`.forgejo/actions/setup-python-env/action.yml`) installs
Python via `mirrors/setup-python` and uv via `mirrors/setup-uv`, then runs
`uv sync --frozen`.

---

## Action Mirrors

All `uses:` references in workflows must point to the Forgejo `mirrors` org using
full URLs. See [forgejo.md — mirrors org](forgejo.md#mirrors-org--action-mirrors)
for the full mirror table.

Pattern for referencing a mirrored action:
```yaml
uses: https://forgejo.kecskemethy.org/mirrors/<action-name>@<ref>
```

---

## Planned

### Semgrep OSS (SAST)

Add as a job in `main.yml` after `quality`. Zero idle RAM — runs in a pipeline pod:

```yaml
  semgrep:
    runs-on: ubuntu-latest
    container:
      image: semgrep/semgrep:latest
    steps:
      - uses: https://forgejo.kecskemethy.org/mirrors/checkout@v4
      - name: Run Semgrep
        run: semgrep scan --config=auto --error
        env:
          SEMGREP_APP_TOKEN: ${{ secrets.SEMGREP_APP_TOKEN }}
```

Or OSS-only without the cloud token:
```yaml
      - name: Run Semgrep OSS
        run: semgrep scan --config=auto --error --no-suppress-errors
```

### Trivy (container + dependency vulnerability scan)

Add as a job in `main.yml` after the Docker build step (if `dockerfile=y`):

```yaml
  trivy:
    runs-on: ubuntu-latest
    steps:
      - uses: https://forgejo.kecskemethy.org/mirrors/checkout@v4
      - name: Run Trivy vulnerability scanner
        run: |
          curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
          trivy fs --exit-code 1 --severity HIGH,CRITICAL .
```

### CD pipeline

Once a project is deployed to k8s via ArgoCD:
- Forgejo repo webhook → ArgoCD sync trigger on `main` push
- Image built in CI, pushed to `forgejo.kecskemethy.org/<org>/<repo>:<sha>`
- ArgoCD `kustomization` or `values.yaml` image tag updated via a CD step
- ArgoCD detects the change and reconciles

Full CD runbook to be documented once the first Python app is deployed.
