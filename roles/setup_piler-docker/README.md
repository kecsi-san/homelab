# setup_piler-docker

Runs the [Piler](https://www.mailpiler.org/) email archive as a Docker Compose stack: Piler (SMTP listener and web UI), MariaDB, Manticore Search and memcached. The host needs no PHP, nginx, MariaDB or Manticore.

## What it does

- Checks that Docker with the compose plugin is installed. It does not install Docker: use `setup_apt_repos` with `apt_repo_docker: true` first.
- Creates the data directories (`etc`, `store`, `db`, `manticore`) under `piler_data_dir` with the numeric owners of the users inside the images (the containers run without most capabilities and cannot change the owner themselves).
- Writes `compose.yaml`, the MariaDB and Manticore configuration, and a secrets file (`piler.env`, mode 0600) to `piler_project_dir`.
- Starts the stack with `docker compose up -d`. A changed file recreates the affected containers.
- Optionally replaces the upstream default passwords of the built-in `admin` and `auditor` users.

The images are upstream's (`sutoj/piler`, `mariadb`, `manticoresearch/manticore`, `memcached`), pinned by version. The role does not configure a mail server: it publishes Piler's SMTP port and the web UI on loopback, and something on the host (a mail transfer agent, a reverse proxy) connects to them.

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `piler_docker_enabled` | `false` | Playbooks run the role only when true |
| `piler_version` | `1.4.9` | `sutoj/piler` image tag |
| `piler_mariadb_version` | `12.0.2` | MariaDB image tag |
| `piler_manticore_version` | `25.0.0` | Manticore image tag |
| `piler_memcached_version` | `1.6.45` | memcached image tag |
| `piler_hostname` | `archive.example.com` | The archive's own host name (required, the role stops on the example value) |
| `piler_site_url` | empty | Public URL of the web UI behind a TLS proxy (for example `https://archive.example.com/`); replaces the `http://` address the image writes on its first start |
| `piler_project_dir` | `/opt/piler` | Compose file, configuration and secrets file |
| `piler_data_dir` | `/srv/piler` | Data on its own volume: `etc` (piler.conf and piler.key), `store`, `db`, `manticore` |
| `piler_smtp_bind` | `127.0.0.1:2525` | Where Piler's SMTP port is published |
| `piler_http_bind` | `127.0.0.1:8080` | Where the web UI is published |
| `piler_db_name`, `piler_db_user` | `piler` | Database name and user |
| `piler_db_password` | none | Database password (required, keep it in Vault) |
| `piler_admin_password_hash` | empty | crypt(3) hash for the built-in `admin` user, for example from `openssl passwd -6`. Empty keeps the upstream default password |
| `piler_auditor_password_hash` | empty | Same for the built-in `auditor` user |
| `piler_memory_limit` | `1g` | Container limits: Piler, MariaDB (`piler_mariadb_memory_limit`, default `2g`), Manticore (`piler_manticore_memory_limit`, default `3g`) |
| `piler_mariadb_innodb_buffer_pool_size` | `1G` | InnoDB buffer pool |
| `piler_manticore_rt_mem_limit` | `1024M` | Real-time index memory before it is flushed; keep it below the container limit |
| `piler_memcached_memory_mb` | `64` | memcached memory |
| `piler_log_max_size`, `piler_log_max_file` | `10m`, `3` | Container log rotation (Docker keeps logs forever by default) |

## Notes

- **Back up `etc/piler.key`.** Without it the stored messages cannot be read. Keep a copy outside the host. The key is created on the first start.
- **Secrets are read once.** MariaDB reads `piler_db_password` only when it creates the database. Changing the variable later does not change the password inside an existing database.
- **Passwords with a `$` sign work** in the hash variables, because the secrets file uses single quotes. Do not pass a hash through Ansible's `environment:`: the shell around `become` expands the `$` signs.
- **Upgrade.** Raise `piler_version` and run the role. Back up the database and the message store first, and keep the previous tag for a rollback.
- **Sizing.** The default limits suit a large archive (tens of gigabytes). A small archive runs with much less; lower the limits and the buffer pool together.
- Upstream's published ports are `25` and `80` on all interfaces; this role binds loopback so that a host mail server can keep port 25.
