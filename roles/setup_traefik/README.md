# setup_traefik

Installs Traefik ingress controller via Helm into a Kubernetes cluster.

Designed to run as part of `post-k8s.yml` (homelab) or `post-k3s.yml` (k3s local),
delegating Helm calls to localhost regardless of which hosts the play targets.

After the initial Ansible bootstrap, Traefik's configuration (service type, kube-vip
annotation, IngressRoutes, TLS) is managed by ArgoCD via the GitOps repo.

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `traefik_enabled` | `true` | Set to `false` to skip the role entirely |
| `traefik_namespace` | `traefik` | Kubernetes namespace |
| `traefik_helm_release_name` | `traefik` | Helm release name |
| `traefik_helm_repo_name` | `traefik` | Helm repo alias |
| `traefik_helm_repo_url` | `https://traefik.github.io/charts` | Helm repo URL |
| `traefik_chart_version` | `34.4.1` | Chart version; pin for reproducibility |
| `traefik_kubeconfig` | `""` | Path to kubeconfig; empty = uses `KUBECONFIG` env var |
| `traefik_service_type` | `ClusterIP` | Service type at install time (see note below) |
| `traefik_helm_values` | see defaults | Full Helm values dict; override as needed |

## Service type note

The role installs Traefik with `service.type: ClusterIP` by default. The LoadBalancer
service and kube-vip annotation are applied later by ArgoCD from the GitOps repo.
This avoids a race condition where two services claim the same IP during migration.

## Usage

In `post-k8s.yml` (homelab; targets `kube` group, delegates Helm to localhost):

```yaml
- name: Install Traefik ingress controller
  ansible.builtin.import_role:
    name: setup_traefik
  vars:
    traefik_kubeconfig: "~/.kube/k8s.yaml"
  tags:
    - traefik
```

In `post-k3s.yml` (k3s local; targets `localhost`):

```yaml
- name: Install Traefik ingress controller
  ansible.builtin.import_role:
    name: setup_traefik
  vars:
    traefik_kubeconfig: "~/.kube/k3s.yaml"
  tags:
    - traefik
```

## Upgrading Traefik

Update `traefik_chart_version` in `defaults/main.yml` and re-run the playbook.
The Helm task is idempotent; it upgrades if the version differs.
