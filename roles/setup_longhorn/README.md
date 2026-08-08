# setup_longhorn

Installs and configures [Longhorn](https://longhorn.io): a lightweight, cloud-native distributed block storage system for Kubernetes. Longhorn turns the local disks of your cluster nodes into replicated, highly available persistent volumes without requiring an external SAN or NFS server.

## Why this role exists

Kubernetes does not include a built-in distributed block storage solution. Longhorn fills that gap by:

- Providing `ReadWriteOnce` and `ReadWriteMany` persistent volumes backed by node-local disks
- Replicating volume data across multiple nodes for fault tolerance
- Offering built-in snapshot and backup support (to S3-compatible targets or NFS)
- Exposing a web UI for storage visibility and management

This role automates the full installation lifecycle: OS-level prerequisites on every node, the `longhornctl` preflight CLI, and the Helm chart deployment; so the cluster is ready to provision persistent volumes after a single playbook run.

## Requirements

- Kubernetes cluster already running (deploy with `playbooks/kubespray.yml` first)
- `kubectl` configured on the Ansible control node (kubeconfig in `~/.kube/`)
- `kubernetes.core` collection installed (`ansible-galaxy collection install kubernetes.core`)
- Helm 3 installed on the Ansible control node
- `csi_snapshot_controller_enabled: true` set in `inventory/group_vars/k8s_cluster/addons.yml` (already enabled in this repo)

## Role variables

### Defaults (`defaults/main.yml`): override in inventory or playbook

| Variable | Default | Description |
|---|---|---|
| `install_requirements` | `true` | Install OS packages required by Longhorn on each node |
| `install_longhorn_cli` | `true` | Download the `longhornctl` binary to each node |
| `run_preflight_check` | `false` | Run `longhornctl check preflight` and print results |
| `install_longhorn` | `true` | Deploy Longhorn via Helm (runs once from control node) |
| `longhorn_version` | `"1.11.0"` | Longhorn version for both the CLI and the Helm chart |
| `longhorn_namespace` | `"longhorn-system"` | Kubernetes namespace for the Longhorn deployment |
| `longhorn_helm_release_name` | `"longhorn"` | Helm release name |

### Internal vars (`vars/main.yml`): not intended to be overridden

| Variable | Value | Description |
|---|---|---|
| `longhorncli_os` | `linux` | Target OS for the CLI binary download |
| `longhorncli_arch` | `amd64` | CPU architecture for the CLI binary download |
| `longhorncli_install_path` | `/usr/local/bin/longhornctl` | Installation path for the `longhornctl` binary |
| `longhorn_helm_repo_name` | `longhorn` | Helm repository alias |
| `longhorn_helm_repo_url` | `https://charts.longhorn.io` | Helm repository URL |

### OS-specific vars (`vars/os/Debian.yml`)

`longhorn_requirement_packages`: list of APT packages installed on each node before Longhorn is deployed. Covers iSCSI initiator, NFS client, device-mapper, and cryptsetup for optional LUKS encryption support.

## Tags

All tasks are tagged `longhorn`. Use this to run only this role when included in a larger playbook:

```bash
ansible-playbook playbooks/post-kubespray.yml --tags longhorn
```

## Example usage

### Run the full role (default)

```bash
ansible-playbook playbooks/post-kubespray.yml
```

### Only install node prerequisites (skip Helm deploy)

```bash
ansible-playbook playbooks/post-kubespray.yml -e install_longhorn=false
```

### Run preflight check before deploying

```bash
ansible-playbook playbooks/post-kubespray.yml -e run_preflight_check=true -e install_longhorn=false
```

### Upgrade Longhorn to a newer version

```bash
ansible-playbook playbooks/post-kubespray.yml -e longhorn_version=1.12.0
```

## What the role does (task order)

1. **Load OS vars**: includes `vars/os/Debian.yml` for the package list
2. **Install packages**: APT packages required by Longhorn on every node (`become: true`)
3. **Start iscsid**: enables and starts the iSCSI initiator daemon (`become: true`)
4. **Check longhornctl**: skips download if the binary is already present
5. **Download longhornctl**: fetches the binary from GitHub and places it in `/usr/local/bin/` (`become: true`)
6. **Preflight check** *(optional)*; runs `longhornctl check preflight` and prints the output; non-blocking
7. **Add Helm repo**: adds `https://charts.longhorn.io` (delegated to localhost, runs once)
8. **Helm install**: deploys the Longhorn chart into `longhorn-system` and waits for it to become ready (delegated to localhost, runs once)

## Post-install

Once deployed, the Longhorn UI is available via the service in the `longhorn-system` namespace. To access it locally:

```bash
kubectl port-forward -n longhorn-system svc/longhorn-frontend 8080:80
```

Then open `http://localhost:8080` in your browser.

Longhorn will register itself as a `StorageClass` named `longhorn`. To make it the cluster default:

```bash
kubectl patch storageclass longhorn -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

## References

- [Longhorn documentation](https://longhorn.io/docs/1.11.0/)
- [Installation requirements](https://longhorn.io/docs/1.11.0/deploy/install/#installation-requirements)
- [longhornctl reference](https://longhorn.io/docs/1.11.0/advanced-resources/longhornctl/)
- [Longhorn Helm chart](https://artifacthub.io/packages/helm/longhorn/longhorn)
