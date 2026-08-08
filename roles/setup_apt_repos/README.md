# setup_apt_repos

Manages custom APT repositories and installs packages from them.

Local-only role; not included in `k8s-nodes.yml`.

Each repository is independently controlled by a boolean flag in `defaults/main.yml` (all off by default except Docker).

## Repositories

| Flag | Default | Repo | Installs |
|------|---------|------|---------|
| `apt_repo_docker` | `true` | docker.com | docker-ce, docker-ce-cli, containerd.io, buildx, compose |
| `apt_repo_grafana` | `false` | apt.grafana.com | grafana |
| `apt_repo_telegraf` | `false` | repos.influxdata.com | telegraf |
| `apt_repo_charm` | `false` | repo.charm.sh | gum |
| `apt_repo_mise` | `false` | mise.jdx.dev | mise |
| `apt_repo_mozilla` | `false` | packages.mozilla.org | firefox, thunderbird (see `mozilla_packages`) |
| `apt_repo_sury_php` | `false` | packages.sury.org | repo only; install PHP version separately |
| `apt_repo_gitea` | `false` | packaging.gitlab.io/gitea | repo only; install `gitea` separately |
| `apt_repo_duosecurity` | `false` | pkg.duosecurity.com | duo-unix |
| `apt_repo_twilio` | `false` | twilio-cli-prod.s3.amazonaws.com | twilio |
| `apt_repo_yarn` | `false` | dl.yarnpkg.com | yarn (no recommends) |
| `apt_repo_microsoft` | `false` | packages.microsoft.com | repo only; install packages (VS Code, Azure CLI, etc.) separately |
| `apt_repo_nodesource` | `false` | deb.nodesource.com | nodejs (see `nodejs_apt_major_version`); purges Debian's own node packages first, see Notes |

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `docker_arch` | auto-detected | CPU arch for apt repos (`amd64`, `arm64`, `armhf`) |
| `docker_packages` | see defaults | Docker CE packages to install |
| `mozilla_packages` | `[firefox]` | Packages to install from Mozilla repo (e.g. firefox, thunderbird) |
| `apt_repo_*` | see table above | Enable/disable individual repositories |
| `nodejs_apt_major_version` | `"24"` | NodeSource major version line to track (e.g. `"24"`, `"22"`) |
| `nodejs_apt_purge_distro_packages` | `true` | Purge Debian's `nodejs`/`npm`/`nodejs-doc`/`libnode-dev` before installing NodeSource's package |
| `nodejs_apt_distro_conflict_packages` | see defaults | Package list purged by the above |

## GPG key handling

All keys are stored in `/etc/apt/keyrings/` using the modern `signed-by=` approach. No `apt-key` usage.

| Repo | Key file | Format |
|------|----------|--------|
| Docker | `/etc/apt/keyrings/docker.asc` | ASCII |
| Grafana | `/etc/apt/keyrings/grafana.asc` | ASCII |
| InfluxDB/Telegraf | `/etc/apt/keyrings/influxdb.asc` | ASCII |
| Mise | `/etc/apt/keyrings/mise.asc` | ASCII |
| Mozilla | `/etc/apt/keyrings/packages.mozilla.org.asc` | ASCII |
| Sury PHP | `/etc/apt/keyrings/sury-php.gpg` | binary |
| Gitea | `/etc/apt/keyrings/gitea.asc` | ASCII |
| Duo Security | `/etc/apt/keyrings/duosecurity.asc` | ASCII |
| Twilio | `/etc/apt/keyrings/twilio.asc` | ASCII |
| Yarn | `/etc/apt/keyrings/yarn.asc` | ASCII |
| Microsoft | `/etc/apt/keyrings/microsoft.asc` | ASCII |
| NodeSource | `/etc/apt/keyrings/nodesource.gpg` | binary (dearmored from the published ASCII key) |

## Notes

- **Charm** uses `[trusted=yes]`: the repo is self-signed with no published GPG key.
- **Mozilla** installs an apt pin (`/etc/apt/preferences.d/mozilla`, priority 1000) to prefer packages from packages.mozilla.org over Debian's Firefox ESR.
- **Gitea** and **Sury PHP** add the repo only; install specific packages in a subsequent play.
- **Microsoft** repo targets Debian only (`packages.microsoft.com/debian/<major>/prod`); useful as a prerequisite for VS Code, Azure CLI, PowerShell, etc.
- **Golang**: not managed here; install via Homebrew (`brew install go`) instead of the Ubuntu-only PPA.
- **NodeSource**: uses the distro-agnostic `nodistro` repo (same URL across Debian/Ubuntu releases). By default also purges Debian's own `nodejs`/`npm`/`nodejs-doc`/`libnode-dev` packages first; third-party repos are normally lower apt priority than the distro's own, so without this NodeSource's package silently loses and the old distro version keeps winning. Set `nodejs_apt_purge_distro_packages: false` to skip the purge (e.g. if you'd rather manage the pin yourself). See `setup_nodejs-dev-tools`/`upgrade_nodejs` for the higher-level roles that call this with `nodejs_install_method: apt-nodesource`.
- After first Docker run, log out and back in (or `newgrp docker`) for group membership to take effect.

## Usage

```yaml
- name: Setup apt repositories
  ansible.builtin.import_role:
    name: setup_apt_repos
  become: true
  tags:
    - apt-repos
    - docker
```

Enable additional repos in `group_vars/local.yml`:

```yaml
apt_repo_grafana: true
apt_repo_telegraf: true
```
