# role_template

Starter template; copy this directory and rename it to begin a new role.

```bash
cp -r roles/role_template roles/<verb>_<subject>
```

Then replace all occurrences of `<role-name>` and `role_template` with your actual role name.

---

## What it does

_Describe what this role does in 1-3 sentences._

## What it does (detailed)

_Optional step-by-step breakdown of tasks._

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `example_var` | `true` | _Description_ |

## Usage

```yaml
- name: <Human-readable task name>
  ansible.builtin.import_role:
    name: <role-name>
  become: true   # or false
  tags:
    - <primary-tag>
```

Run standalone:

```bash
ansible-playbook -t <primary-tag> playbooks/k8s-nodes.yml
```

## Notes

- _Any caveats, dependencies, or important behaviour to call out._
