# setup_argocd-apps

One-time bootstrap: applies the cert-manager `ClusterIssuer` and the ArgoCD
root `Application` (`kube-gitops/{k8s,k3s}/root.yaml`). After this, ArgoCD's
app-of-apps pattern self-manages every child `Application` from Git; this
role never runs again in the normal reconcile loop, only on cluster rebuild.

## What it does

- Templates a `ClusterIssuer` manifest (Let's Encrypt prod, DNS01 via
  Cloudflare) and applies it with `kubectl apply`
- Applies `kube-gitops/{{ argocd_apps_cluster_type }}/root.yaml`, the ArgoCD
  root `Application` that watches the `apps/` directory for that cluster

## Variables

| Variable | Default | Description |
|----------|---------|--------------|
| `argocd_apps_enabled` | `true` | Set to `false` to skip the role entirely |
| `argocd_apps_cluster_type` | `k3s` | Selects `kube-gitops/{k3s,k8s}/root.yaml`, set per playbook |
| `argocd_apps_kubeconfig` | `""` | Path to kubeconfig; empty falls back to `KUBECONFIG` env var / `~/.kube/config` |

`acme_email` (used by the `ClusterIssuer` template) isn't defined in this
role's own defaults; it comes from `inventory/group_vars/all/vars.yml`.

## Usage

```yaml
- name: Bootstrap ArgoCD root application
  ansible.builtin.import_role:
    name: setup_argocd-apps
  vars:
    argocd_apps_kubeconfig: "~/.kube/k8s.yaml"
    argocd_apps_cluster_type: k8s
  tags:
    - argocd-apps
```

Wired into both `post-k8s.yml` (`argocd_apps_cluster_type: k8s`) and
`post-k3s.yml` (`argocd_apps_cluster_type: k3s`), always paired with
`setup_argocd` (k3s) or an already-installed ArgoCD (k8s), since ArgoCD
itself has to exist before this role's `kubectl apply` of the root
`Application` can succeed.

## Notes

- `ClusterIssuer` apply runs unconditionally on every playbook run
  (`changed_when: true`); it's cheap and idempotent server-side, so this
  isn't gated behind `argocd_apps_enabled`.
- The root `Application` apply, by contrast, respects `argocd_apps_enabled`
  and derives `changed_when` from kubectl's own stdout (`created`/
  `configured`), so it accurately no-ops once bootstrapped.
- `run_once: true`, `delegate_to: localhost`: kubectl targets the cluster
  via kubeconfig, not the Ansible-managed hosts.
