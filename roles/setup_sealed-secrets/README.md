# setup_sealed-secrets

Installs the [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets) controller
via Helm into a Kubernetes cluster.

Sealed Secrets lets you encrypt Kubernetes secrets with a cluster-specific public key so
the ciphertext is safe to commit to a git repository. Only the controller running in the
cluster can decrypt them.

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `sealed_secrets_enabled` | `true` | Set to `false` to skip the role entirely |
| `sealed_secrets_namespace` | `sealed-secrets` | Kubernetes namespace |
| `sealed_secrets_helm_release_name` | `sealed-secrets` | Helm release name |
| `sealed_secrets_helm_repo_name` | `sealed-secrets` | Helm repo alias |
| `sealed_secrets_helm_repo_url` | `https://bitnami-labs.github.io/sealed-secrets` | Helm repo URL |
| `sealed_secrets_chart_version` | `2.16.1` | Chart version (app v0.27.1); pin for reproducibility |
| `sealed_secrets_kubeconfig` | `""` | Path to kubeconfig; empty = uses `KUBECONFIG` env var |

## Usage

In `post-k8s.yml` (homelab):

```yaml
- name: Install Sealed Secrets controller
  ansible.builtin.import_role:
    name: setup_sealed-secrets
  vars:
    sealed_secrets_kubeconfig: "~/.kube/k8s.yaml"
  tags:
    - sealed-secrets
```

In `post-k3s.yml` (k3s local):

```yaml
- name: Install Sealed Secrets controller
  ansible.builtin.import_role:
    name: setup_sealed-secrets
  vars:
    sealed_secrets_kubeconfig: "~/.kube/k3s.yaml"
  tags:
    - sealed-secrets
```

## Sealing secrets with kubeseal

Install `kubeseal` CLI (via Homebrew: `brew install kubeseal`).

Because the controller runs in the `sealed-secrets` namespace (not `kube-system`),
you must pass `--controller-namespace` and `--controller-name` to kubeseal:

```bash
# Create a raw secret (never commit this)
kubectl create secret generic my-secret \
  --from-literal=token=supersecret \
  --dry-run=client -o yaml > /tmp/my-secret.yaml

# Seal it (safe to commit)
kubeseal \
  --controller-namespace sealed-secrets \
  --controller-name sealed-secrets \
  --format yaml \
  < /tmp/my-secret.yaml > my-secret-sealed.yaml

# Clean up plaintext
rm /tmp/my-secret.yaml
```

## Important: secrets are cluster-specific

A secret sealed for the homelab cluster cannot be decrypted by the k3s cluster and
vice versa. Each cluster has its own key pair. Seal secrets separately per cluster.

## Upgrading

Update `sealed_secrets_chart_version` in `defaults/main.yml` and re-run the playbook.
The Helm task is idempotent; it upgrades if the version differs.
