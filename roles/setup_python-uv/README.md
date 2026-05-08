# setup_python-uv

Installs Python-based DevOps tools and libraries using [uv](https://github.com/astral-sh/uv).

Covers **Tier 3** of the tool management strategy (Python-only packages). See [Tool Management Philosophy](../../README.md#tool-management-philosophy).

## What it does

1. Installs CLI tools via `uv tool install` — each in an isolated virtualenv, linked to `~/.local/bin`
2. Adds `~/.local/bin` to `PATH` in `~/.bashrc`
3. Creates a shared `~/.venv/devops` virtualenv for library packages
4. Installs library packages into the devops venv via `uv pip install`
5. Optionally activates the devops venv automatically in `~/.bashrc`

---

## CLI tools — `uv tool install`

| Tool | Version | Purpose |
|------|---------|---------|
| `ansible-core` | `>=2.18,<2.19` | Infrastructure automation CLI (pinned for Kubespray 2.31) |
| `ansible-lint` | latest | Ansible playbook linter |
| `checkov` | latest | IaC security scanner |
| `git-changelog` | latest | Changelog generator from git history |
| `pip-audit` | latest | Python dependency vulnerability scanner |
| `ruff` | latest | Python linter and formatter |
| `yamllint` | latest | YAML linter |

`ansible-core` includes `netaddr` as an extra dependency (required by Kubespray's `ansible.utils.ipaddr` filter).

## Library packages — `uv pip install` into `~/.venv/devops`

| Package | Purpose |
|---------|---------|
| `atlassian-python-api` | Jira / Confluence / Bitbucket REST client |
| `datadog-api-client` | Datadog API client |
| `diagrams` | Diagrams-as-code (cloud architecture) |
| `graphviz` | Graphviz Python bindings |
| `hvac` | HashiCorp Vault API client |
| `jira` | Jira REST API client |
| `jsonpath-ng` | JSONPath expressions for Python |
| `lxml` | XML/HTML processing |
| `markdown2` | Markdown to HTML converter |
| `matplotlib` | Data visualisation / plotting |
| `nc-py-api` | Nextcloud API client |
| `openai` | OpenAI API client |
| `pyhcl` | HashiCorp Configuration Language (HCL) parser |
| `PyJWT` | JSON Web Token encode/decode |
| `pyOpenSSL` | OpenSSL bindings |
| `python-jenkins` | Jenkins REST API client |
| `requests-mock` | Mock HTTP requests in tests |
| `setuptools-scm` | Version management from git tags |
| `tfparse` | Terraform HCL parser |
| `tinycss2` | CSS parser |

---

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `python_version` | `3.12` | Python version for uv tool installs and the devops venv |
| `uv_bin` | (OS-specific) | Path to the uv binary |
| `uv_venv_path` | `~/.venv/devops` | Path for the shared library venv |
| `uv_venv_autoactivate` | `true` | Add `source ~/.venv/devops/bin/activate` to `~/.bashrc` |
| `uv_tools` | see `defaults/main.yml` | List of tools for `uv tool install` |
| `uv_pip_packages` | see `defaults/main.yml` | List of packages for `uv pip install` |

### Tool list item fields

```yaml
uv_tools:
  - name: ansible-core       # package name (required)
    version: ">=2.18,<2.19"  # version constraint appended to name (optional)
    extras:                  # additional packages via --with (optional)
      - netaddr
```

---

## Prerequisites

- `uv` must be installed before running this role (via Homebrew: `install_linuxbrew` + `uv` in `setup_minimal` brew packages)

## Usage

```yaml
- name: Setup Python uv packages
  ansible.builtin.import_role:
    name: setup_python-uv
  become: false
  tags:
    - python
    - uv
```

## Notes

- `become: false` — all packages are installed in user space
- `changed_when: false` on install/upgrade tasks — uv is idempotent; use `upgrade_python-uv` to upgrade
- Adding packages to the lists installs them on next run; removing them does not uninstall automatically
- `ansible-core` is pinned to `>=2.18,<2.19` — Kubespray release-2.31 requires ansible-core 2.18.x
- Do not install `ansible` or `ansible-core` into the devops venv — conflicts with the uv tool and causes PATH shadowing issues

## Platform limitations

**Currently Linux-only.** `uv_bin` defaults to the Linuxbrew path (`/home/linuxbrew/.linuxbrew/bin/uv`). macOS support would require detecting the Homebrew prefix (`/opt/homebrew` on Apple Silicon, `/usr/local` on Intel).
