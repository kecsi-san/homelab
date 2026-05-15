# CI/CD

## Overview

Two GitHub Actions workflows run automatically on pushes to `main`:

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `lint.yml` | push + pull_request to `main` | Validate YAML formatting and Ansible best practices |
| `changelog.yml` | push to `main` | Generate and commit `CHANGELOG.md` from conventional commits |

No deployment automation — all cluster and workstation changes are applied manually via `ansible-playbook`.

---

## Workflow: lint.yml

### Triggers

| Event | Branch |
|-------|--------|
| `push` | `main` |
| `pull_request` | `main` |

### Concurrency

A `concurrency` group is set to `${{ github.workflow }}-${{ github.ref }}` with
`cancel-in-progress: true`. Pushing multiple commits quickly cancels the previous run
rather than queuing redundant jobs.

### Runner

`ubuntu-24.04` — pinned to a specific Ubuntu version so the environment does not change
silently when GitHub updates `ubuntu-latest`.

### Timeout

`timeout-minutes: 10` — prevents a hung step (e.g. a stalled `ansible-galaxy` download)
from blocking the shared runner indefinitely.

---

## Steps

```
Checkout
  └─ Set up Python 3.12 (pip cache keyed on requirements-lint.txt)
       └─ Install linting tools (ansible-lint, yamllint)
            └─ Restore Ansible collections cache (keyed on requirements.yml)
                 └─ Install collections [skipped on cache hit]
                      └─ Create vault password file
                           ├─ Run yamllint
                           └─ Run ansible-lint  ← always runs, even if yamllint fails
```

### Caching

| Cache | Key | Path |
|-------|-----|------|
| pip packages | `pip-<hash of requirements-lint.txt>` | `~/.cache/pip` (managed by `actions/setup-python`) |
| Ansible collections | `ansible-collections-<hash of requirements.yml>` | `~/.ansible/collections` |

The collections install step is skipped entirely on a cache hit, saving ~45 seconds per run.
The cache invalidates automatically when `requirements.yml` changes.

### Vault password

The Ansible Vault password is stored as a GitHub Actions secret named `ANSIBLE_VAULT_PASSWORD`.
It is written to `~/.vault_pass.txt` using `printf` (not `echo`) to correctly handle passwords
containing special characters or no trailing newline. The path matches `vault_password_file`
in `ansible.cfg`.

**Dependabot PRs:** Dependabot does not have access to repository secrets by default.
When the vault password is unavailable, ansible-lint is skipped entirely and a `::notice::`
annotation is emitted pointing to the fix (add `ANSIBLE_VAULT_PASSWORD` to Dependabot secrets
in repo Settings → Secrets and variables → Dependabot). `yamllint` still runs on all PRs.

### Linter behaviour

- `yamllint` always runs, even if triggered by Dependabot
- `ansible-lint` runs only when `ANSIBLE_VAULT_PASSWORD` is available; skipped with a notice otherwise

---

## Linting tools

### yamllint

Configured via `.yamllint` (project root). Runs in strict mode. The same configuration is
used by the pre-commit hook for local feedback before push.

### ansible-lint

Configured via `.ansible-lint` (project root):

| Setting | Value | Reason |
|---------|-------|--------|
| `profile` | `moderate` | Balanced — catches real issues without noise |
| `offline` | `true` | Skips galaxy role downloads; roles are mocked |
| `mock_roles` | `markosamuli.linuxbrew` | Vendored galaxy role — prevents "role not found" error |
| `exclude_paths` | `.venv/`, `collections/`, `roles/markosamuli.linuxbrew/`, `playbooks/k8s.yml`, `playbooks/reset-k8s.yml`, `kube-gitops/` | Kubespray collection and plain Kubernetes YAML not for ansible-lint |
| `skip_list` | `yaml[line-length]`, `var-naming[no-role-prefix]`, `role-name` | Intentional deviations — see ROLES.md for naming conventions |

Ansible collections required by the playbooks (`community.general`, `ansible.posix`,
`kubernetes.core`) are installed at lint time. The Kubespray collection is excluded
because it is a full git repo (~200 MB) that is unnecessary for linting.

---

## Local pre-commit hooks

Pre-commit is configured in `.pre-commit-config.yaml` and uses system-installed tools
(installed via the `setup_python-uv` role) to avoid version conflicts.

| Hook | Runs on | Notes |
|------|---------|-------|
| `yamllint` | every commit | Fast (~1s); catches YAML errors before push |
| `ansible-lint` | CI only | ~70s locally — too slow for pre-commit; runs in GitHub Actions instead |

Install hooks once after cloning:

```bash
pre-commit install
```

---

## Version pinning

Linting tool versions are pinned in `requirements-lint.txt`:

```
ansible-lint>=26.4.0,<27
yamllint>=1.38.0,<2
```

Update these deliberately after testing new versions locally:

```bash
uv tool list          # see current local versions
# update requirements-lint.txt, push, confirm CI passes
```

---

---

## Workflow: changelog.yml

### Triggers

| Event | Branch |
|-------|--------|
| `push` | `main` |

### Concurrency

Same `${{ github.workflow }}-${{ github.ref }}` group with `cancel-in-progress: true` — a
rapid series of commits produces one changelog update, not several racing ones.

### What it does

1. Checks out the full git history (`fetch-depth: 0` — required to read all commits)
2. Installs [`git-changelog`](https://pawamoy.github.io/git-changelog/) via pip
3. Runs `git-changelog -o CHANGELOG.md` — parses conventional commits and renders `CHANGELOG.md`
4. Commits the result back to `main` only if the file changed, using the message
   `docs: update CHANGELOG.md [skip ci]`

The `[skip ci]` suffix prevents the commit from triggering `lint.yml` or another
changelog run.

### Permissions

`contents: write` is required to push the `CHANGELOG.md` commit back to `main`.

### Conventional commits

`git-changelog` expects commit messages to follow the
[Conventional Commits](https://www.conventionalcommits.org/) spec
(`feat:`, `fix:`, `chore:`, `ci:`, `docs:`, etc.). Commits that don't follow the spec
are still included but grouped under an "Other" section.

---

## Dependabot

`.github/dependabot.yml` opens weekly pull requests for two ecosystems:

| Ecosystem | What gets bumped | Directory |
|-----------|-----------------|-----------|
| `github-actions` | `actions/checkout`, `actions/setup-python`, `actions/cache` | `/` |
| `pip` | `requirements.txt` (ansible, ansible-lint, yamllint, etc.) | `/` |

Commit message prefix: `chore`. ansible-lint is skipped on Dependabot PRs unless
`ANSIBLE_VAULT_PASSWORD` is also added to Dependabot secrets (see Vault password section above).

---

## Adding a new playbook

When a new playbook is added, check whether it uses modules from a collection not yet
installed in the CI workflow. If so, add the collection to the `Install Ansible collections`
step in `lint.yml`. If it delegates to an external tool like Kubespray, add it to
`exclude_paths` in `.ansible-lint` instead.
