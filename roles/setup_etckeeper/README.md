# setup_etckeeper

Installs and initialises etckeeper to track `/etc` changes in git.

## What it does

1. Installs the `etckeeper` package via APT
2. Configures `/root/.gitconfig` with the specified user name and email
3. Checks for an init marker to prevent re-initialisation on subsequent runs
4. Runs `etckeeper init` and makes an initial commit (first run only)
5. Creates `/etc/.etckeeper.initmarker` to record that init has been done

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `etckeeper_user` | `{{ admin_user }}` | Git user name for root's gitconfig |
| `etckeeper_email` | `{{ admin_email }}` | Git email for root's gitconfig |

## Usage

```yaml
- name: Setup etckeeper
  ansible.builtin.import_role:
    name: setup_etckeeper
  become: true
  tags:
    - etckeeper
```

## Notes

- Requires `become: true`
- `etckeeper` is enabled in group_vars (`etckeeper: true`) but the role is not yet wired into any playbook; add it to `k8s-nodes.yml` to activate
- Idempotent: the init marker prevents double-initialisation
