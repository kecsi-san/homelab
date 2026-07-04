# configure_git

Installs `git-lfs` and deploys a templated `~/.gitconfig` to the remote user's home directory.

## What it does

- Installs `git-lfs` (apt on Linux, Homebrew on macOS) — required by the `[filter "lfs"]` block in the deployed gitconfig; without it, any repo/file hitting an LFS filter hard-fails (`required = true`)
- Runs `git lfs install --skip-repo` to register the global LFS filters without touching any specific repo's hooks
- Renders `templates/gitconfig.j2` to `{{ ansible_env.HOME }}/.gitconfig` (`ansible.builtin.template`, not `copy` — the file has Jinja placeholders for `user.name`/`user.email`/`user.signingkey`)
- Sets owner and group to the current user

## Variables

| Variable | Source | Description |
|----------|--------|--------------|
| `git_user_name` | defaults to `admin_full_name` (vaulted in `local.yml`) | Git user name |
| `git_user_email` | defaults to `admin_email` (vaulted in `local.yml`) | Git user email |
| `git_user_signingkey` | defaults to `git_user_signkey` (vaulted in `local.yml`) | GPG signing key ID (see TODO below) |
| `git_user_gpgsign` | `false` | Drives `[commit] gpgsign`. Stays `false` until GPG key distribution is solved, see TODO below |

## TODO: GPG signing key distribution

`user.signingkey` in the deployed gitconfig references a GPG key ID, but this role does **not** deploy the actual private key material — `[commit] gpgsign` is hardcoded `false` so this doesn't break anything today, but it means the signing key config is a dangling reference until each machine's keyring has the real key imported manually.

Plan: distribute the GPG private key via HashiCorp Vault (`setup_vault` role) once Vault is actually initialized and unsealed — it currently isn't (see `roles/setup_vault/README.md`). Until then, importing the key remains a manual per-machine step.

## Usage

```yaml
- name: Configure git
  ansible.builtin.import_role:
    name: configure_git
  become: false
  tags:
    - gitconfig
    - git
    - developer
```

Note: `become: true` is applied internally on the Linux git-lfs package install task only, per this repo's `become: false` at play level / `become: true` per-task-that-needs-it convention.

## Notes

- Wired into `k8s-nodes.yml` (remote `kube` group), `local-core.yml`, and `personalise.yml`. First real run against this WSL2 workstation (2026-07-04) surfaced two pre-existing bugs, both fixed: the role used `ansible.builtin.copy` on a file with unrendered Jinja placeholders (now `template`), and `defaults/main.yml` referenced a vaulted variable name (`git_signing_key`) that didn't actually exist — the real name in `local.yml` is `git_user_signkey`.
- GPG commit signing is **disabled** (`gpgsign = false`) — despite `signingkey` being set, see TODO above.
