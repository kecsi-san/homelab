# setup_argocd

Installs ArgoCD via Helm (`argo-helm` chart). Bootstraps the ArgoCD control
plane itself, since ArgoCD can't manage its own initial installation via
GitOps.

## What it does

- Adds the `argo` Helm repo
- Installs/upgrades the `argocd` release with `server.insecure: "true"`
  (Traefik terminates TLS in front of ArgoCD, so ArgoCD itself serves plain
  HTTP), `wait: true`
- Retrieves and prints the initial admin password from the
  `argocd-initial-admin-secret` Kubernetes secret

## Variables

| Variable | Default | Description |
|----------|---------|--------------|
| `argocd_enabled` | `true` | Set to `false` to skip the role entirely |
| `argocd_namespace` | `argocd` | Kubernetes namespace |
| `argocd_helm_release_name` | `argocd` | Helm release name |
| `argocd_helm_repo_name` | `argo` | Helm repo alias |
| `argocd_helm_repo_url` | `https://argoproj.github.io/argo-helm` | Helm repo URL |
| `argocd_chart_version` | `"7.7.5"` | Chart version (ships ArgoCD v2.14.x); check https://github.com/argoproj/argo-helm for latest. **Not Renovate-tracked**, this is a manual periodic check (see `TODO.md`) |
| `argocd_kubeconfig` | `""` | Path to kubeconfig; empty falls back to `KUBECONFIG` env var / `~/.kube/config` |
| `argocd_helm_values` | `configs.params.server.insecure: "true"` | Full Helm values dict; override as needed |

## Usage

Wired into `post-k3s.yml`. On the k8s cluster, `post-k8s.yml` doesn't import
this role: it only patches the existing `argocd-cmd-params-cm` ConfigMap
for Traefik-terminated TLS, assuming ArgoCD is already installed; see
`docs/ansible/roles.md` for current per-playbook wiring if that changes.

```yaml
- name: Install ArgoCD
  ansible.builtin.import_role:
    name: setup_argocd
  vars:
    argocd_kubeconfig: "~/.kube/k3s.yaml"
  tags:
    - argocd
```

## Notes

- Runs `delegate_to: localhost`, `run_once: true`: Helm/kubectl operations
  target the cluster via kubeconfig, not the Ansible-managed hosts
  themselves.
- The `argocd-config` ArgoCD app (`kube-gitops/{k8s,k3s}/argocd/`) is the
  GitOps-managed follow-up that layers CM/RBAC/OIDC config on top of what
  this role installs; it can't replace this role's initial Helm install.
- Password retrieval is best-effort (`failed_when: false`); if the secret
  is already gone (e.g. a prior manual admin password change deleted it),
  the debug message is simply skipped.
