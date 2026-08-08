# setup_cloud-gcp

Installs Google Cloud CLI tooling for local development and infrastructure work.

## What it does

| Tool | Formula | Default | Purpose |
|------|---------|---------|---------|
| `google-cloud-sdk` | `google-cloud-sdk` | always | `gcloud`, `gsutil`, `bq`: all bundled |
| `gke-gcloud-auth-plugin` | `gke-gcloud-auth-plugin` | optional | kubectl auth plugin for GKE clusters |
| `cloud-sql-proxy` | `cloud-sql-proxy` | optional | Secure local connections to Cloud SQL instances |

All tools installed via Homebrew; cross-platform (Linux + macOS).

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `gcp_enabled` | `true` | Set to `false` to skip the role entirely |
| `gcp_brew_packages` | `[google-cloud-sdk]` | Core packages; always installed |
| `gcp_optional_brew_packages` | all `false` | Optional tools; flip to `true` to install |

## Usage

```yaml
- name: Setup GCP cloud tooling
  ansible.builtin.import_role:
    name: setup_cloud-gcp
  when: gcp_enabled
  vars:
    gcp_enabled: true
    gcp_optional_brew_packages:
      gke-gcloud-auth-plugin: false
      cloud-sql-proxy: false
  tags:
    - cloud
    - gcp
```

## Notes

- `become: false`: all Homebrew installs are user-space
- `google-cloud-sdk` bundles `gcloud`, `gsutil` and `bq`: no need to install them separately
- `gke-gcloud-auth-plugin` is required for GKE clusters using Workload Identity / modern auth
- After install, run `gcloud init` and `gcloud auth application-default login` to authenticate
