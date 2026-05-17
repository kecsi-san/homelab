---
title: "Modern Python Project Templates for 2025–2026"
type: research
status: stable
scope: [general]
created: 2026-05-17
updated: 2026-05-17
tags: [python, uv, templates, ci, tooling]
---

# Modern Python Project Templates for 2025–2026

**Scope:** Seven actively maintained Python project templates evaluated for homelab and internal
tooling use, with background on the tool choices that underpin them.
Research conducted May 2026 against live repositories.

---

## Table of Contents

1. [Background: Why the Tooling Landscape Changed](#background-why-the-tooling-landscape-changed)
2. [Template 1: cookiecutter-uv (fpgmaas)](#template-1-cookiecutter-uv-fpgmaas)
3. [Template 2: simple-modern-uv (jlevy)](#template-2-simple-modern-uv-jlevy)
4. [Template 3: copier-uv (pawamoy)](#template-3-copier-uv-pawamoy)
5. [Template 4: python-boilerplate (smarlhens)](#template-4-python-boilerplate-smarlhens)
6. [Template 5: python-project-generator (sanders41)](#template-5-python-project-generator-sanders41)
7. [Template 6: python-project-template (a1d4r)](#template-6-python-project-template-a1d4r)
8. [Template 7: python-uv (a5chin)](#template-7-python-uv-a5chin)
9. [Tool Debates](#tool-debates)
10. [Decision Matrix](#decision-matrix)
11. [Recommendation for Homelab / Internal Tooling on Forgejo CI](#recommendation-for-homelab--internal-tooling-on-forgejo-ci)

---

## Background: Why the Tooling Landscape Changed

The Python packaging ecosystem went through a major consolidation between 2023 and 2026.
Three forces drove it:

- **uv** (Astral, written in Rust) landed in 2024 and by 2025 had replaced most serious use
  of pip+venv, pipenv, and Poetry for new projects. It is 10–100x faster than pip, ships its
  own Python installer, produces cross-platform lock files, and unifies `pip`, `venv`, `pipx`,
  `pyenv`, and `pip-tools` into a single binary.
- **ruff** (also Astral, also Rust) replaced the black+flake8+isort+pydocstyle+pyupgrade stack
  with a single sub-millisecond tool that is configuration-compatible with each of those tools.
- **ty** (Astral again, announced 2025, alpha as of May 2026) is challenging mypy and pyright
  as the type checker of record, advertising 10–100x speed improvements.

All six templates surveyed here have converged on uv+ruff. They diverge meaningfully on type
checker choice, template engine, CI target, documentation tooling, and opinionatedness level.

---

## Template 1: cookiecutter-uv (fpgmaas)

**Repository:** <https://github.com/fpgmaas/cookiecutter-uv>
**Maintainer:** Florian Maas (now under the `osprey-oss` GitHub org)
**Stars:** 1,294 | **Forks:** 189 | **Last push:** 2026-05-16
**License:** MIT
**Releases:** 0.0.12 (2026-04-10), 0.0.11 (2025-07-31), 0.0.10 (2025-05-10)

### Description and Philosophy

The most starred and broadly adopted template in this survey. Its philosophy is **sensible
defaults with optional extras**: every major feature (Docker, devcontainer, docs, type checker,
codecov, deptry, layout) is presented as a yes/no prompt during generation, so you only get
what you asked for.

Maintained under the `osprey-oss` organisation. Has its own CI tooling
(`cookiecutter_uv/cicd/`) that auto-updates dependency versions inside the template on a
schedule — a rare and genuinely useful feature.

### Tool Stack

| Concern | Tool | Notes |
|---|---|---|
| Package manager | uv | Latest pinned version in CI |
| Linter | ruff | Broad rule set (YTT, S, B, A, C4, T10, SIM, I, C90, E, W, F, PGH, UP, RUF, TRY) |
| Formatter | ruff format | Black-compatible, preview mode enabled |
| Type checker | mypy **or** ty | Chosen at generation time |
| Dep audit | deptry | Optional; checks for unused/missing deps |
| Test framework | pytest | With optional pytest-cov + codecov upload |
| Multi-version test | tox-uv | tox configured to run under uv |
| Task runner | Makefile | `install`, `check`, `test`, `build`, `publish`, `docs-test`, `docs` targets |
| Pre-commit | pre-commit | ruff-check, ruff-format + pre-commit-hooks (yaml, toml, json, eol, trailing-ws) |
| Docs | MkDocs Material **or** Zensical **or** none | Zensical added 2026-04-10 |
| Containerisation | Docker **or** Podman | Optional Dockerfile |
| Dev environment | VS Code devcontainer | Optional |
| CI | GitHub Actions | `main.yml` (quality+tests), `on-release-main.yml` (PyPI publish) |

### Project Structure (src layout)

```
my-project/
├── src/
│   └── my_project/
│       └── __init__.py
├── tests/
│   └── __init__.py
├── docs/
│   └── index.md
├── .github/
│   ├── actions/setup-python-env/action.yml
│   └── workflows/
│       ├── main.yml
│       ├── on-release-main.yml
│       └── validate-codecov-config.yml
├── .devcontainer/
├── .pre-commit-config.yaml
├── Dockerfile
├── Makefile
├── pyproject.toml
├── tox.ini
└── README.md
```

### How to Use It

```bash
uvx cookiecutter https://github.com/osprey-oss/cookiecutter-uv.git
```

**Prompts:** author/email/github, project name/description, layout (src/flat),
github actions, publish to PyPI, deptry, docs tool, codecov, dockerfile,
devcontainer, type checker (mypy/ty), licence.

After generation: `make install` sets up the virtualenv and pre-commit hooks.

### CI Workflow

`main.yml` triggers on push to `main` and pull requests. Two jobs run in parallel:

1. **`quality`** (ubuntu-latest): `uv lock --locked`, pre-commit hooks (ruff), type
   checker, optional deptry
2. **`tests-and-type-check`** (matrix: Python 3.10–3.14): pytest + coverage, optional
   Codecov upload on Python 3.11 only
3. **`check-docs`** (if docs selected): `uv run mkdocs build -s`

`on-release-main.yml` on GitHub release: re-runs quality + tests, publishes to PyPI via
OIDC trusted publishing (no API token needed).

`update-dependencies.yml` on schedule: auto-updates pinned dependency versions inside the
template via `cookiecutter_uv/cicd/`.

### Pros

- Largest community (1,294 stars, 189 forks) — most likely to have existing answers
- Widest feature surface, all optional — you get exactly what you ask for
- `tox-uv` for multi-Python testing rare among these templates; valuable for libraries
- `update-dependencies.yml` keeps pinned versions current automatically
- Zensical docs support added April 2026
- deptry catches imports not declared in pyproject.toml

### Cons

- Cookiecutter: **no update mechanism** after initial generation; template improvements
  don't flow back to existing projects
- CI auto-update workflow is GitHub Actions specific; does nothing for Forgejo users
- Codecov requires paid account for private repos
- tox adds complexity for applications that don't need multi-Python testing
- `on-release-main.yml` PyPI workflow only relevant for open-source library authors

### Best Suited For

Open-source Python library authors and teams wanting the most complete, battle-tested
starting point with GitHub as their CI platform. Widest configurability without writing
template logic yourself.

---

## Template 2: simple-modern-uv (jlevy)

**Repository:** <https://github.com/jlevy/simple-modern-uv>
**Maintainer:** Joshua Levy
**Stars:** 278 | **Forks:** 28 | **Last push:** 2026-02-19
**License:** MIT
**Releases:** v0.2.25 (2026-02-15)

### Description and Philosophy

**3 Ms: minimalist, modern, and maintained.** The author's personal migration template as
he moved from Poetry to uv. The README explicitly commits to keeping the template readable
in about 10 minutes (~300 lines of template code total).

Uses **Copier** — the most important architectural decision: generated projects can pull
future template improvements back in via `copier update`.

### Tool Stack

| Concern | Tool | Notes |
|---|---|---|
| Package manager | uv | src layout |
| Linter | ruff | Curated subset: E, F, UP, B, I — intentionally not exhaustive |
| Formatter | ruff format | Black-compatible |
| Type checker | BasedPyright | Explicitly chosen over mypy and standard Pyright |
| Spell checker | codespell | Drop-in, no configuration required |
| Test framework | pytest + pytest-sugar | pytest-sugar gives nicer terminal output |
| Versioning | uv-dynamic-versioning + hatchling | Version derived from git tags; no version commits |
| Task runner | Makefile (thin) | ~30 lines; delegates to `uv run` |
| Lint script | `devtools/lint.py` | Python script using `rich` + `funlog`; runs codespell, ruff, basedpyright |
| Pre-commit | None | Intentional; linting is CI-enforced only |
| Docs | Markdown files only | `docs/installation.md`, `docs/development.md`, `docs/publishing.md` |
| CI | GitHub Actions | `ci.yml` (build+test), `publish.yml` (PyPI) |

### Project Structure

```
my-project/
├── src/
│   └── my_module/
│       ├── __init__.py
│       ├── my_module.py
│       └── py.typed
├── tests/
│   └── test_placeholder.py
├── devtools/
│   └── lint.py
├── docs/
│   ├── development.md
│   ├── installation.md
│   └── publishing.md
├── .github/workflows/
│   ├── ci.yml
│   └── publish.yml
├── .copier-answers.yml
├── Makefile
├── pyproject.toml
└── README.md
```

### How to Use It

```bash
# With companion CLI:
uvx uvtemplate

# Directly with Copier:
uvx copier copy gh:jlevy/simple-modern-uv /path/to/new-project

# Update an existing project from template:
copier update
```

### CI Workflow

`ci.yml` triggers on push and PRs to `main`/`master`. Single job, matrix:
`os: [ubuntu-latest]`, `python-version: [3.11, 3.12, 3.13, 3.14]`.

Steps: checkout (fetch-depth: 0 for dynamic versioning), setup-uv, `uv sync --all-extras`,
`uv run python devtools/lint.py` (codespell + ruff + basedpyright), `uv run pytest`.

### Pros

- True minimalism; fast to read, fork, and understand
- Copier-based: `copier update` merges template improvements into existing projects
- BasedPyright significantly faster than mypy, excellent VS Code/Cursor integration
- Dynamic git-tag versioning eliminates version-bump commits
- `devtools/lint.py` gives prettier terminal output and is easier to debug than pre-commit
- pytest-sugar quality-of-life improvement
- `uvtemplate` companion CLI makes bootstrapping simple

### Cons

- Lower adoption (278 stars)
- No pre-commit hooks: linting failures surface only in CI
- BasedPyright is a Pyright fork; migration friction if team is invested in mypy plugins
- No Docker, devcontainer, or docs site generator
- No update since 2026-02-19; may be considered stable or drifting

### Best Suited For

Individual developers or small teams who want the simplest possible starting point, value
Copier's update mechanism, and prefer to understand every line of their tooling.

---

## Template 3: copier-uv (pawamoy)

**Repository:** <https://github.com/pawamoy/copier-uv>
**Maintainer:** Timothée Mazzucotelli (pawamoy), prominent Python OSS contributor
**Stars:** 148 | **Forks:** 30 | **Last push:** 2026-03-05
**License:** ISC
**Releases:** 1.11.15 (2026-03-05)

### Description and Philosophy

The maintainer's own production template used across many of his OSS projects. The README
is upfront: "This copier template is mainly for my own usage." The template reflects one
expert developer's complete, integrated workflow — not a community consensus approach.

**Professional-grade developer experience with every tool integrated**: conventional commits
→ automatic changelog → automated API breaking-change detection → duty task runner →
Zensical docs → cross-platform CI (Linux + macOS + Windows + Python dev builds).

The task runner is `duty` (the author's own library): tasks defined in `duties.py` as
Python functions decorated with `@duty`, making them unit-testable and IDE-navigable.

### Tool Stack

| Concern | Tool | Notes |
|---|---|---|
| Package manager | uv | |
| Build backend | pdm-backend | Not hatchling or uv_build |
| Linter | ruff | Config in `config/ruff.toml` |
| Formatter | ruff format | |
| Type checker | ty | Replaces mypy in recent updates |
| Test framework | pytest + pytest-cov + pytest-randomly + pytest-xdist | Full test suite |
| API tracking | griffe | Detects breaking changes in public API between commits |
| Changelog | git-changelog | Auto-generates CHANGELOG.md from conventional commits |
| Legacy checks | yore | Checks for deprecated code patterns |
| Task runner | duty | Python-native task runner (author's own library) |
| Docs | Zensical | With Material theme and mkdocstrings plugin |
| CI | GitHub Actions | Multi-OS, multi-Python version matrix |

### Project Structure

```
my-project/
├── src/my_package/
│   ├── __init__.py
│   ├── py.typed
│   └── _internal/
├── tests/
├── scripts/
├── docs/
│   ├── index.md
│   ├── changelog.md
│   ├── contributing.md
│   ├── credits.md
│   └── reference/api.md
├── config/
│   ├── ruff.toml
│   ├── pytest.ini
│   ├── coverage.ini
│   ├── git-changelog.toml
│   └── ty.toml
├── .github/workflows/
│   ├── ci.yml
│   └── release.yml
├── duties.py
├── pyproject.toml
├── CHANGELOG.md
└── zensical.toml
```

### How to Use It

```bash
# --trust required for Jinja extensions (git introspection):
uvx copier copy --trust "gh:pawamoy/copier-uv" /path/to/new-project

# Update:
copier update --trust
```

### CI Workflow

**`ci.yml`** triggers on push to `main` and `test-me-*` branches, and PRs.

`quality` job matrix: `os: [ubuntu-latest, macos-latest, windows-latest]` × Python
3.10–3.14 plus `3.15-dev`. For each: `make setup`, `make check-docs`,
`make check-quality`, `make check-types`, `make check-api` (griffe breaking changes).

`tests` job (depends on quality): same OS/Python matrix, pytest + coverage.

`release.yml` on `v*` tag push: builds wheel, creates GitHub release, optional PyPI publish.

### Pros

- `duty` tasks are Python functions: testable, IDE-navigable, self-documenting
- griffe API break detection: fails CI on accidental public API breakage — unique feature
- Auto-changelog from conventional commits eliminates manual release notes
- Copier-based with full update capability
- Cross-platform CI including macOS, Windows, and `3.15-dev`
- Battle-tested: the author uses this for real production packages

### Cons

- **Not for beginners**: duty + griffe + git-changelog + yore + Zensical + pdm-backend
  is a significant learning investment
- `duty` is the author's own library; carries a bus-factor risk
- pdm-backend is non-standard in 2026; `uv_build` or hatchling would be more conventional
- `--trust` flag for copier is a security consideration in automated pipelines
- GitHub-only CI (no Forgejo/GitLab support in copier.yml)
- Conventional commits requirement is implicit — no hard enforcement at commit time

### Best Suited For

Experienced Python OSS library maintainers wanting a professional-grade, fully integrated
workflow and willing to learn the full toolchain. Not appropriate for internal apps or
teams new to Python packaging.

---

## Template 4: python-boilerplate (smarlhens)

**Repository:** <https://github.com/smarlhens/python-boilerplate>
**Maintainer:** Samuel Marlhens
**Stars:** 85 | **Forks:** 16 | **Last push:** 2026-05-15
**License:** MIT

### Description and Philosophy

**Not a template generator** — a **reference boilerplate repository** you clone and adapt.
Always updated to the **absolute bleeding edge**: Python 3.14, uv 0.11.x, ruff 0.15.x,
and uniquely **both mypy and ty run simultaneously** as blocking type checkers. Also uses
`uv_build` (newest build backend), `oxfmt` (Rust-based OXC formatter for YAML/JSON/MD),
and bandit for security scanning.

### Tool Stack

| Concern | Tool | Version (May 2026) |
|---|---|---|
| Package manager | uv | >=0.11.5 |
| Build backend | uv_build | >=0.11.5,<0.12.0 |
| Python | 3.14 | Pinned in `.python-version` |
| Linter | ruff | 0.15.12 |
| Formatter | ruff format | 0.15.12 |
| Type checkers | mypy **and** ty | Both as blocking checks |
| Security scanner | bandit | 1.9.4 |
| Test framework | pytest + pytest-cov | |
| Pre-commit | pre-commit | ruff, ruff-format, mypy, ty (local), bandit, pytest (local), oxfmt |
| Non-Python formatter | oxfmt (OXC) | v0.47.0 (YAML, JSON, Markdown) |
| Dependency updates | Renovate | `.renovaterc.json5` |
| Security analysis | CodeQL | GitHub Actions `codeql.yml` |
| Containerisation | Docker | Standard Dockerfile |
| CI | GitHub Actions | `ci.yml` + `codeql.yml` |

### How to Use It

Not a generator — clone and rename:

```bash
git clone https://github.com/smarlhens/python-boilerplate.git my-project
cd my-project && rm -rf .git && git init
pre-commit install
uv python install && uv sync
uv run pytest tests
```

Then rename `src/python_boilerplate/` and update `pyproject.toml`.

### CI Workflow

`ci.yml` (ubuntu-24.04): `uv sync`, ruff check, ruff format, mypy (strict), ty (all
warnings as errors), bandit, pytest + coverage, `uv build`, Docker build validation.

`codeql.yml`: GitHub CodeQL security analysis on push/PR.

### Pros

- Fastest to adopt: clone, rename, start coding
- Bleeding-edge tooling choices — useful as a reference for where the ecosystem is heading
- Running both mypy and ty simultaneously is uniquely valuable during ty's alpha period
- Renovate for automatic dependency PRs (better than Dependabot for Python packages)
- CodeQL security scanning absent from most templates
- oxfmt for non-Python files (YAML, JSON, Markdown) fills a gap others ignore
- `uv_build` build backend — fully in the Astral ecosystem

### Cons

- No generator: no prompts; manually edit everything to suit your project
- No update mechanism
- Python 3.14 requirement narrows compatibility
- No multi-Python CI — single version only
- No task runner, docs tooling, or template community
- Running both mypy and ty doubles type-checking time (both are fast, but still)
- `uv_build` strict version pin (`<0.12.0`) needs frequent updating

### Best Suited For

Teams wanting to see and directly copy the absolute latest Python tooling choices, or as a
reference implementation to borrow specific configurations from (especially the dual mypy+ty
config and Renovate setup).

---

## Template 5: python-project-generator (sanders41)

**Repository:** <https://github.com/sanders41/python-project-generator>
**Maintainer:** Paul Sanders
**Stars:** 28 | **Forks:** 3 | **Last push:** 2026-05-15
**License:** MIT
**Releases:** v3.2.5 (2026-05-15)

### Description and Philosophy

A **Rust-native CLI generator** distributed as a compiled binary. The generator itself is
not Python code. Unique feature: **queries PyPI's API at generation time** to get current
latest versions of ruff, mypy, pytest-cov, etc. and writes them into the generated
`pyproject.toml` — no stale pinned versions.

Supports three project types: pure Python, Python+Rust (PyO3/maturin), and FastAPI
(the most complete FastAPI scaffold of any template here: asyncpg, Pydantic, Granian,
Valkey caching, Traefik, sqlx migrations).

### Tool Stack

| Concern | Tool | Notes |
|---|---|---|
| Package manager | uv / poetry / setuptools | Chosen at generation time |
| Linter | ruff | |
| Formatter | ruff format | |
| Type checker | mypy | Only option; no ty support yet |
| Test framework | pytest + pytest-cov | pytest-asyncio if async selected |
| Task runner | justfile | PyO3 projects only |
| Multi-OS CI | Optional | Linux only or Linux+macOS+Windows |
| Docs | MkDocs + Material + mkdocstrings | Optional |
| Dependency updates | Dependabot | Optional, configurable schedule |
| Release drafter | Release Drafter | Optional |
| Containerisation | Docker | FastAPI projects |

### How to Use It

```bash
# Install (Cargo):
cargo install python-project-generator
# or .deb binary from GitHub releases

# Generate:
python-project create
```

Prompts cover: licence, Python versions, CI OS matrix, package manager, async support,
Dependabot, multi-OS CI, docs inclusion, release drafter.

### Pros

- Rust binary: no Python/pip/virtualenv needed to run the generator
- Live PyPI version checking: generated files have actual latest versions at creation time
- FastAPI scaffold is uniquely complete: full async application stack
- PyO3/maturin support for Python+Rust extensions — unique among these templates
- Actively maintained: 3 releases in May 2026 alone

### Cons

- Requires Cargo/Rust to install (`.deb` eases Debian/Ubuntu)
- Only 28 stars; minimal community
- mypy only; no ty support
- No Copier/Cookiecutter update mechanism
- No Forgejo CI support
- FastAPI feature requires compile-time flag (`-F fastapi`)

### Best Suited For

Developers building FastAPI services or PyO3 Rust extensions who want a complete scaffold
and are comfortable installing a Rust binary.

---

## Template 6: python-project-template (a1d4r)

**Repository:** <https://github.com/a1d4r/python-project-template>
**Maintainer:** a1d4r
**Stars:** 23 | **Forks:** 2 | **Last push:** 2026-04-05
**License:** None specified

### Description and Philosophy

A **Cookiecutter template** targeting teams who use **both GitHub and GitLab**. Dual
platform CI support is the differentiating feature — generated projects include both
`.github/workflows/lint-test.yml` and `.gitlab-ci.yml`.

Comprehensive Makefile (~80 targets) as the task runner. ruff with `select = ["ALL"]` is
the most rigorous lint configuration in this survey. Includes Pydantic integration with
the mypy pydantic plugin, and typeguard for runtime type checking in tests.

### Tool Stack

| Concern | Tool | Notes |
|---|---|---|
| Package manager | uv | `package = false` by default (application-oriented) |
| Build backend | None | No `[build-system]` — app only |
| Linter | ruff | `select = ["ALL"]` with targeted ignores |
| Formatter | ruff format | |
| Type checker | mypy (strict) | Optional pydantic-mypy plugin |
| Security checker | safety | Checks dependencies for known CVEs |
| Dep audit | deptry | |
| Runtime type check | typeguard | In tests: validates runtime type assertions |
| Test framework | pytest + pytest-cov | junit XML + coverage XML output |
| Task runner | Makefile | ~80 targets |
| Pre-commit | pre-commit | ruff, ruff-format |
| CI platforms | GitHub Actions **+ GitLab CI** | Both included |
| Containerisation | Docker + docker-compose | For local development |

### How to Use It

```bash
pip install -U cookiecutter
cookiecutter gh:a1d4r/python-project-template --checkout main
```

Prompts: project/package name, git platform (github/gitlab), username, Python version
(3.9–3.13), line length, install pydantic (y/n).

### CI Workflow

**GitHub Actions `lint-test.yml`** — two parallel jobs:

`lint`: uv sync, `uv lock --check` + deptry, ruff format check, ruff check (GitHub
annotation output), mypy (strict).

`test`: pytest + coverage, coverage PR summary comment via sticky-pull-request-comment,
coverage added to GitHub Job Summary.

**GitLab CI `.gitlab-ci.yml`**: equivalent lint + test stages with mypy-gitlab-code-quality
integration for GitLab's built-in code quality reports.

### Pros

- Only template here with **GitLab CI** support alongside GitHub Actions
- Pydantic + mypy plugin integration out of the box
- typeguard in tests catches type errors not caught by static analysis alone
- safety dependency vulnerability scanning
- ruff with `select = ["ALL"]` — highest lint bar of any template here
- docker-compose for local development practical for apps talking to databases
- Coverage PR comments (sticky-pull-request-comment)

### Cons

- **Flat layout** (not src) — Python Packaging Authority now recommends src layout
- Cookiecutter-based: no update mechanism
- No licence specified — legally awkward to copy/redistribute
- No ty support; no docs tooling
- safety requires paid account for reliable CVE data since 2023
- Python 3.9–3.13 only; no 3.14 support
- No dynamic versioning

### Best Suited For

Teams already on GitLab, or using both GitLab and GitHub, especially those using Pydantic
heavily and wanting the most comprehensive ruff ruleset.

---

## Template 7: python-uv (a5chin)

**Repository:** <https://github.com/a5chin/python-uv>
**Maintainer:** a5chin
**Stars:** 369 | **Forks:** 21 | **Last push:** 2025-11-20
**License:** MIT
**Template engine:** None (direct clone / Use this template button)

### Description and Philosophy

A focused, opinionated template with a distinctive **Dev Container + GHCR image
publishing** angle. Rather than abstracting over CI or docs, it makes one strong bet:
the development environment is a fully specified container that can be rebuilt from
scratch on any machine, and that same container image is pushed to GitHub Container
Registry as part of CI.

The target audience is developers who want a reproducible, container-first development
environment — not just a reproducible build, but a reproducible *workspace*.

### Tool Stack

| Concern | Tool | Notes |
|---|---|---|
| Package manager | uv | |
| Linter | ruff | |
| Formatter | ruff format | |
| Type checker | ty | Astral's pre-alpha type checker (as of May 2026) |
| Test framework | pytest | |
| Dev environment | VS Code Dev Container | Core differentiator; `.devcontainer/` fully specified |
| Container registry | GHCR (GitHub Container Registry) | CI publishes the dev container image |
| CI | GitHub Actions | Build + push to GHCR; lint + test workflow |
| Target Python | 3.14 | Tracks Python's development branch |

### Project Structure

```
python-uv/
├── .devcontainer/
│   ├── devcontainer.json
│   └── Dockerfile
├── .github/
│   └── workflows/
│       ├── ci.yml         (lint + test)
│       └── docker.yml     (build + push to GHCR)
├── src/
│   └── <package>/
├── tests/
├── pyproject.toml
├── uv.lock
└── Makefile
```

### Distinctive Features

**Dev Container as first-class citizen:** The `.devcontainer/` setup is more than a
convenience — it is the official development environment. The `devcontainer.json`
specifies VS Code extensions, settings, and post-create commands so every contributor
gets an identical environment without local tool installation.

**GHCR publishing workflow:** `docker.yml` builds the dev container image and pushes it
to `ghcr.io/<owner>/<repo>`. This means the CI image is versioned alongside the code and
can be pulled by any collaborator without building locally. Unusual to find in a small
template; typically a feature of enterprise CI setups.

**ty as type checker:** Adopts Astral's `ty` before it reaches stable release. Demonstrates
confidence in the Astral ecosystem but introduces risk for production code (ty alpha is known
to miss some complex type patterns).

**Python 3.14 target:** Tracks CPython's development branch. Progressive for exploration;
risky for anything requiring stability.

### Caveats

- **No scaffolding / prompts**: the template is cloned as-is; there is no Cookiecutter or
  Copier integration. Renaming `<package>` requires manual find-and-replace across files.
- **ty is pre-stable (alpha as of May 2026)**: suitable for exploration; not yet recommended
  as the sole type checker for production internal tooling.
- **Python 3.14**: CPython 3.14 is in pre-release; dependencies may lack 3.14 wheels;
  `uv python install 3.14` installs a pre-release binary. For stable homelab tooling,
  pin to 3.12 or 3.13 after cloning.
- **No update mechanism**: clone once; drift from upstream is manual.
- **GCP dependency reference in README**: Some context in the docs assumes GCP tooling
  (likely the author's professional context); not relevant to the homelab but easy to
  remove.

### Pros

- Dev Container + GHCR publishing is a distinctive, production-quality CI pattern not
  found in the other templates; directly applicable to homelab services running in k8s
  (same image used for dev and deployment)
- Clean src layout, uv, ruff — aligns with the recommended toolchain
- Very low boilerplate: starter code is minimal; structure enforces good habits without
  adding noise
- Small and readable: easy to understand every file in the template

### Cons

- No scaffolding: find-and-replace setup is tedious compared to Cookiecutter/Copier generation
- ty in alpha: type errors may be missed; switch to mypy or wait for ty stable for production
- Python 3.14 target: needs downgrade for stable homelab use
- Stars (369) significantly lower than cookiecutter-uv (1,294); less community support

### Best Suited For

Developers who want a **container-first development environment** and plan to publish the dev
container image to a registry. The GHCR workflow is directly translatable to the Forgejo
container registry with a one-line URL change. Pairs well with homelab projects where the
dev container is also the deployment container (no separate Dockerfile needed).

**Verdict for this homelab**: Worth adding as a reference / secondary pattern. The GHCR
publishing workflow translates directly to Forgejo's built-in OCI registry
(`forgejo.kecskemethy.org/<user>/<repo>`) — change the registry URL and swap GHCR login
for Forgejo token auth. Not the primary recommendation because of the no-scaffolding
friction and ty alpha risk, but the Dev Container + OCI publish pattern is worth borrowing.

---

## Tool Debates

### uv vs pip / poetry / pipenv

The consensus in the Python community by 2025 has strongly shifted toward uv:

- **Speed**: 10–100x faster than pip for dependency resolution and installation. `pip install`
  can take 60–90 seconds in CI; `uv sync` takes 2–5 seconds for the same environment.
- **Unification**: replaces pip, venv, pyenv, pipx, pip-tools, and parts of Poetry with one
  binary. `uv python install` manages Python itself (via python-build-standalone).
- **Lock files**: cross-platform (`uv.lock`); Poetry's `poetry.lock` and pip's
  `requirements.txt` are platform-specific.
- **Drop-in compatibility**: `uv pip install`, `uv pip freeze`, `uv venv` are identical
  to pip/venv.

**Remaining concerns (2026)**: uv has not reached 1.0; large pypi cache can grow (20GB+);
GitHub Dependabot does not yet update `uv.lock` (Renovate does); corporate proxies sometimes
struggle with uv's parallel download strategy.

**Bottom line**: for new projects in 2025–2026, uv is the correct choice.

### ruff vs black+isort

ruff has effectively won. By 2025, the black+isort+flake8+pydocstyle+pyupgrade combination
(5 tools, 5 configuration sections) has been replaced by a single ruff binary that:

- Formats identically to black in 99.9%+ of cases
- Sorts imports identically to isort when `profile = "black"` is set
- Implements 700+ lint rules covering flake8 + 50+ plugins
- Runs in milliseconds on large codebases
- Has a single `pyproject.toml` configuration section

The only reason to stay with black+isort: existing tooling deeply integrated with black's API
or regulatory requirements mandating specific tool provenance.

**All seven templates** in this survey use ruff for both linting and formatting.

### mypy vs pyright vs ty in 2025–2026

This is the most actively shifting debate as of May 2026:

**mypy**: Original, most widely deployed. Mature plugin ecosystem (pydantic-mypy,
sqlalchemy-stubs, django-stubs). Runs in 30–120 seconds on large projects. Reference
implementation for PEP 484/526/544 compliance.

**Pyright** (Microsoft): 5–10x faster than mypy. Powers Pylance (VS Code). Strong type
narrowing and protocol support. Limited plugin ecosystem compared to mypy.

**BasedPyright**: Community fork of Pyright with more aggressive defaults. Used by
`simple-modern-uv`. Carries the risk of falling out of sync with upstream Pyright.

**ty** (Astral, alpha as of May 2026): Written in Rust. Claims 10–100x faster than mypy
and Pyright. Has a language server for IDE integration. Missing some advanced type features
in alpha (complex overloads, certain metaclass patterns) but covers the vast majority of
everyday code.

**Traction trajectory:**
- mypy: declining for new projects; retained for codebases with heavy plugin use
- Pyright/BasedPyright: stable; good for VS Code-heavy teams
- ty: rapidly gaining — `copier-uv` switched to ty as primary; `cookiecutter-uv` added ty
  as an alternative; `python-boilerplate` runs both mypy and ty simultaneously

**Practical recommendation**: In 2026, for new projects without mypy plugin dependencies
(no Django, SQLAlchemy), ty is worth adopting alongside mypy during its alpha period. For
Pydantic v2, Pydantic's own annotations are now comprehensive enough that pydantic-mypy is
largely optional.

### Copier vs Cookiecutter

The key functional difference is **template update capability**:

| | Cookiecutter | Copier |
|---|---|---|
| Template engine | Jinja2 | Jinja2 |
| Config format | `cookiecutter.json` | `copier.yml` (YAML, comments allowed) |
| Update mechanism | None (cruft adds it with friction) | `copier update` — three-way merge |
| Answer persistence | None | `.copier-answers.yml` |
| Community | Larger, 10+ years | Growing fast, strong 2022–2024 |
| Trust flag | Not needed | Required when templates use Python extensions |

For homelab/internal tooling: Copier's update mechanism is particularly valuable because
internal projects need to adopt security fixes and tool updates from the template over time.

---

## Decision Matrix

| | cookiecutter-uv | simple-modern-uv | copier-uv | python-boilerplate | python-project-generator | python-project-template | python-uv (a5chin) |
|---|---|---|---|---|---|---|---|
| **Stars** | 1,294 | 278 | 148 | 85 | 28 | 23 | 369 |
| **Template engine** | Cookiecutter | Copier | Copier | None (clone) | Custom (Rust) | Cookiecutter | None (clone) |
| **Update mechanism** | No | Yes | Yes | No | No | No | No |
| **Package manager** | uv | uv | uv | uv | uv/poetry/setuptools | uv | uv |
| **Build backend** | hatchling | hatchling + uv-dynamic-versioning | pdm-backend | uv_build | hatchling | None (app) | hatchling |
| **Type checker** | mypy or ty | BasedPyright | ty | mypy + ty (both) | mypy | mypy | ty (alpha) |
| **Security scan** | No | No | No | bandit + CodeQL | No | safety | No |
| **Task runner** | Makefile | Makefile (thin) | duty (Python) | None | None | Makefile (comprehensive) | Makefile |
| **Pre-commit** | Yes | No | No | Yes | No | Yes | No |
| **Multi-Python CI** | Yes (3.10–3.14) | Yes (3.11–3.14) | Yes (3 OS × 3.10–3.14+dev) | No | Optional | No | No (3.14 only) |
| **Docs** | MkDocs/Zensical/none | Markdown only | Zensical | None | MkDocs optional | None | None |
| **Docker** | Optional | No | No | Yes | FastAPI only | Yes + docker-compose | Dev Container + GHCR |
| **src layout** | Yes or flat | Yes (fixed) | Yes (fixed) | Yes (fixed) | Yes | No (flat, fixed) | Yes (fixed) |
| **GitLab/Forgejo CI** | No | No | No | No | No | Yes (GitLab CI) | No |
| **Dynamic versioning** | No | Yes (git tags) | Yes (git tags) | No | No | No | No |
| **Dep audit (deptry)** | Optional | No | No | No | No | Yes | No |
| **API break detect** | No | No | Yes (griffe) | No | No | No | No |
| **Beginner friendly** | High | Medium | Low | Medium | Medium | Medium | Medium |
| **Last push** | 2026-05-16 | 2026-02-19 | 2026-03-05 | 2026-05-15 | 2026-05-15 | 2026-04-05 | 2025-11-20 |

---

## Recommendation for Homelab / Internal Tooling on Forgejo CI

**Profile**: Building homelab and internal tooling apps (not publishing to PyPI), using
Forgejo for CI, valuing clean well-documented code over minimalism.

### Primary Recommendation: cookiecutter-uv — adapted for Forgejo

**Why it wins for this use case:**

1. **Largest community**: 1,294 stars / 189 forks → answers exist for most problems.
2. **Configurable**: prompt away PyPI publishing, Codecov, tox; keep Docker, devcontainer,
   pre-commit, and docs. You get what internal tooling needs without the library overhead.
3. **Type checker choice**: mypy vs ty prompt — start stable, switch later.
4. **deptry**: catches imports present in the environment but missing from pyproject.toml —
   a problem that bites at containerisation time.
5. **Docker + devcontainer**: optional but included; essential for k8s deployment.

**Forgejo CI adaptation** — Forgejo Actions is compatible with GitHub Actions syntax.
The main change needed is the uv setup action:

```yaml
# Replace (not in Forgejo Actions marketplace):
uses: astral-sh/setup-uv@v5

# With:
- name: Install uv
  run: curl -LsSf https://astral.sh/uv/install.sh | sh && echo "$HOME/.cargo/bin" >> $GITHUB_PATH
```

Delete `on-release-main.yml` entirely (no PyPI publishing for internal tools).

**Suggested answers at generation time for internal tooling:**

| Prompt | Answer |
|---|---|
| `layout` | src |
| `include_github_actions` | y (then adapt for Forgejo) |
| `publish_to_pypi` | n |
| `deptry` | y |
| `docs_tool` | mkdocs |
| `codecov` | n |
| `dockerfile` | y |
| `devcontainer` | y |
| `type_checker` | mypy (switch to ty when it exits alpha) |
| `open_source_license` | Not open source |

**Generation command:**

```bash
uvx cookiecutter https://github.com/osprey-oss/cookiecutter-uv.git
```

### Secondary Recommendation: python-boilerplate as a reference

Use `smarlhens/python-boilerplate` as a **reference implementation** even if not as the
primary starting point. The dual mypy+ty configuration in `pyproject.toml` and `ci.yml`,
and the Renovate configuration, are worth borrowing directly.

### Why the others don't win here

| Template | Reason |
|---|---|
| simple-modern-uv | Too minimal: no pre-commit, no Docker, no docs generator |
| copier-uv (pawamoy) | duty + griffe + pdm-backend overkill for internal apps |
| python-project-generator | Requires Rust install; no Forgejo CI; no update path |
| python-project-template (a1d4r) | Flat layout; no licence; safety CVE data concerns |
| python-uv (a5chin) | No scaffolding (manual rename); ty in alpha; Python 3.14 target needs downgrading — **use as reference for Dev Container + GHCR pattern, not as primary template** |

### Suggested toolchain for new homelab projects in 2026

```
Package manager:    uv (>=0.5.0)
Build backend:      hatchling
Linter:             ruff (comprehensive ruleset, not ALL)
Formatter:          ruff format
Type checker:       mypy (strict) now; add ty as non-blocking second pass
                    → switch ty to blocking once it exits alpha
Security:           bandit (add to pre-commit)
Dep audit:          deptry
Test framework:     pytest + pytest-cov
Task runner:        Makefile (cookiecutter-uv default)
Pre-commit:         yes — ruff, ruff-format, pre-commit-hooks basics
Docs:               MkDocs Material (internal docs for the service)
Versioning:         manual (no PyPI) — git tags + CHANGELOG.md
Containerisation:   Docker (multi-stage, non-root, uv as installer)
CI:                 Forgejo Actions (adapted from GitHub Actions yaml)
```
