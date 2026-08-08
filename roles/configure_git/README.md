# configure_git

Installs `git-lfs` and deploys a templated `~/.gitconfig` to the remote user's home directory.

## What it does

- Installs `git-lfs` (apt on Linux, Homebrew on macOS); required by the `[filter "lfs"]` block in the deployed gitconfig; without it, any repo/file hitting an LFS filter hard-fails (`required = true`)
- Runs `git lfs install --skip-repo` to register the global LFS filters without touching any specific repo's hooks
- Renders `templates/gitconfig.j2` to `{{ ansible_env.HOME }}/.gitconfig` (`ansible.builtin.template`, not `copy`: the file has Jinja placeholders for `user.name`/`user.email`/`user.signingkey`)
- Deploys `~/.ssh/allowed_signers` (only when `git_user_gpgsign` is true) so `git log --show-signature` / the `ll` alias can verify signatures locally, not just GitHub server-side
- Sets owner and group to the current user

## Commit signing: SSH format, not GPG

Uses `gpg.format = ssh` (Git 2.34+) rather than actual GPG; `user.signingkey` points
at a public key file path, and the matching private key is deployed by
**`configure_ssh-client`, which must run before this role** (see `local-core.yml`
task order). Reuses the same `github.com` key already used for pushing, since a
single personal-use signing identity is enough here; see `configure_ssh-client`'s
README for the underlying Vault-backed key layout.

This replaced an earlier GPG-based plan (`user.signingkey` pointing at a GPG key
ID, `gpgsign` hardcoded `false` because the key material was never distributed); abandoned 2026-07-19 after the actual GPG key was lost when its old work computer
was decommissioned.

On the **remote kube nodes** (`k8s-nodes.yml`), `configure_ssh-client` never runs,
so there's no signing key to point at there; that invocation overrides
`git_user_gpgsign: false` explicitly to avoid a dangling key path breaking git
operations (including etckeeper's auto-commits).

## Variables

| Variable | Source | Description |
|----------|--------|--------------|
| `git_user_name` | defaults to `admin_full_name` (vaulted in `local.yml`) | Git user name |
| `git_user_email` | defaults to `admin_email` (vaulted in `local.yml`) | Git user email |
| `git_user_signingkey` | `defaults/main.yml`, `{{ ansible_env.HOME }}/.ssh/github.com.pub` | Path to the SSH public key used for signing |
| `git_user_gpgsign` | `true` (overridden to `false` in `k8s-nodes.yml`) | Drives `[commit] gpgsign` and whether `allowed_signers` gets deployed |

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

- Wired into `k8s-nodes.yml` (remote `kube` group), `local-core.yml`, and `personalise.yml`. First real run against this WSL2 workstation (2026-07-04) surfaced two pre-existing bugs, both fixed: the role used `ansible.builtin.copy` on a file with unrendered Jinja placeholders (now `template`), and `defaults/main.yml` referenced a vaulted variable name (`git_signing_key`) that didn't actually exist; the real name in `local.yml` is `git_user_signkey`.
- Commit signing is **enabled** via SSH format (`gpgsign = true`) on `local-core.yml`/`personalise.yml` runs, **disabled** on remote `k8s-nodes.yml` runs; see "Commit signing" above.
