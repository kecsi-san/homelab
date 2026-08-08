# setup_cloud-aws

Installs AWS CLI tooling for local development and infrastructure work.

## What it does

| Tool | Method | Platform |
|------|--------|----------|
| `awscli` (v2) | Homebrew | Linux + macOS |
| `aws-sam-cli` | Homebrew | Linux + macOS |
| `session-manager-plugin` | Official `.deb` from AWS | Linux only |

`session-manager-plugin` is not available as a Homebrew formula for Linux; it is downloaded directly from the AWS S3 installer bucket and installed via `apt`.

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `aws_enabled` | `true` | Set to `false` to skip the role entirely |
| `aws_brew_packages` | `[awscli, aws-sam-cli]` | Homebrew packages to install |
| `session_manager_plugin_url` | AWS S3 URL | Installer URL for the session manager plugin |
| `session_manager_plugin_deb` | `/tmp/session-manager-plugin.deb` | Temp path for the downloaded `.deb` |

## Usage

```yaml
- name: Setup AWS cloud tooling
  ansible.builtin.import_role:
    name: setup_cloud-aws
  when: aws_enabled
  vars:
    aws_enabled: true
  tags:
    - cloud
    - aws
```

## Notes

- `become: false` for Homebrew installs; user-space
- `become: true` for `apt` install of session-manager-plugin; requires root
- Session Manager Plugin enables SSH/port-forward via SSM without opening inbound ports
