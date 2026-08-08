# setup_headlamp

Installs [Headlamp](https://headlamp.dev): a Kubernetes dashboard; via Helm.

Captures the manual `helm install my-headlamp` that was run on the homelab cluster.
Running this role against the homelab upgrades the existing release and flips the
service from LoadBalancer (.102) to ClusterIP, releasing that IP back to the pool.
Traefik routes to Headlamp via an IngressRoute instead.

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `headlamp_enabled` | `true` | Set to `false` to skip the role entirely |
| `headlamp_namespace` | `kube-system` | Kubernetes namespace |
| `headlamp_helm_release_name` | `my-headlamp` | Helm release name; matches the existing manual install |
| `headlamp_helm_repo_name` | `headlamp` | Helm repo alias |
| `headlamp_helm_repo_url` | `https://kubernetes-sigs.github.io/headlamp/` | Helm repo URL |
| `headlamp_chart_version` | `0.40.0` | Chart version; pin for reproducibility |
| `headlamp_kubeconfig` | `""` | Path to kubeconfig; empty = uses `KUBECONFIG` env var |
| `headlamp_helm_values` | `service.type: ClusterIP` | Full Helm values dict; override as needed |

## Usage

In `post-k8s.yml` (homelab only; Headlamp is not wired into post-k3s.yml by default):

```yaml
- name: Install Headlamp dashboard
  ansible.builtin.import_role:
    name: setup_headlamp
  vars:
    headlamp_kubeconfig: "~/.kube/k8s.yaml"
  tags:
    - headlamp
```

## Migration note

The previous manual install had no Helm values and the service was patched to
`LoadBalancer` with a kube-vip annotation (`kube-vip.io/loadbalancerIPs: 192.168.1.102`)
applied directly to the service object after install.

Running this role replaces that with a Helm-managed `ClusterIP` service. kube-vip will
stop announcing `.102` automatically once the service type changes. The IP is then free
for other use.
