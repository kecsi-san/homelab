# Vault Architecture: Mounts, Access Management, EC2 Secrets Migration

**Status: planned, not yet implemented.**

## Context

Vault is live at `vault.k*.hu` (installed 2026-07-04, initialized/unsealed, CLI configured on the primary workstation with `VAULT_ADDR` set, see `docs/howtos/ec2-rebuild-plan.md` for the install). This doc plans the move from "root token for everything" to a properly designed setup before putting real secrets in it: separate mount points per concern, real access management, and a decision on whether Terraform should manage secret data itself.

**Decisions:**
1. **Terraform manages structure only** (mounts, policies, auth methods), never secret *values*. Terraform state duplicates whatever it manages in plaintext (encrypted at rest via the S3 backend, but still a second place secrets could leak from); HashiCorp's own guidance is against using `vault_kv_secret_v2`-style resources for real secret content. Secret values get written directly via `vault kv put`, entirely outside Terraform's purview.
2. **Scope: EC2/Ansible secrets only, this round.** Today's `inventory/group_vars/all/secrets.yml` (AWS creds, Duo, `apache_certs`/`apache_vhosts`, `ec2_users`, `mailbox_users`, etc.) migrates into Vault. Kubernetes SealedSecrets (49 of them across `kube-gitops/`) and MikroTik/router credentials are explicitly **out of scope**: the former needs a much bigger lift (External Secrets Operator or Vault Agent Injector to actually deliver secrets into pods); the latter has a real bootstrapping risk (if the router or WAN breaks, you'd want router credentials reachable without depending on a network path to Vault) and is better left in the existing vaulted `secrets.yml` as a break-glass fallback.
3. **Human auth stays simple for now**: userpass + a scoped policy for day-to-day use, root token reserved for admin/emergency only. OIDC via Authentik (already used for ArgoCD/Forgejo/Grafana) is a good future enhancement, not a blocker to start using Vault today.

## Architecture

### Mounts (this round)
- `ec2/`: KV v2, holds everything currently in `secrets.yml` that's EC2/Ansible-specific.
- `workstation/`: KV v2, holds personal/workstation secrets migrated from `../dotfiles` (SSH client config + keys, PyPI feed, etc.). Added 2026-07-19, see the "Workstation secrets" addendum below.

### Policies
- `ec2-ansible-read`: read + list only on `ec2/data/*` and `ec2/metadata/*`. Bound to the Ansible AppRole.
- `ec2-dkim-write`: create + update only on `ec2/data/dkim-private/*` and `ec2/data/dkim-public/*`. Bound to the Ansible AppRole alongside `ec2-ansible-read`. See the DKIM addendum below.
- `ec2-admin`: full CRUD on `ec2/*`, for day-to-day `vault kv put/get` work, bound to a userpass login, not root.
- `workstation-admin`: full CRUD on `workstation/*`, bound to the same userpass login as `ec2-admin`.

### Auth methods
- `approle`: for Ansible (machine auth). Role `ansible` bound to `ec2-ansible-read`.
- `userpass`: for the human user, bound to `ec2-admin` and `workstation-admin`. The auth method and policies are Terraform-managed; the actual user+password is created with a manual `vault write auth/userpass/users/<name> password=... policies=ec2-admin,workstation-admin` (a credential, so kept out of Terraform per decision #1).

### Terraform module: `terraform/vault/`
New root module, separate state from `terraform/aws/` (different blast radius: Vault-admin credentials shouldn't be mixed into the same plan/state as AWS infra). Mirrors `terraform/aws/`'s existing backend pattern (same S3 bucket, new state key `vault/terraform.tfstate`; `backend.conf.example` committed, `backend.conf` gitignored).

- `provider.tf`: `hashicorp/vault` provider, address from a variable (default `https://vault.k*.hu`), token via ambient `VAULT_TOKEN`/`~/.vault-token` (never a Terraform variable, this module needs *no* secret tfvars at all, unlike `terraform/aws/`)
- `main.tf`: `vault_mount.ec2`, `vault_policy.ec2_ansible_read`, `vault_policy.ec2_admin`, `vault_auth_backend.approle`, `vault_auth_backend.userpass`, `vault_approle_auth_backend_role.ansible`
- `outputs.tf`: the AppRole `role_id` (stable, not sensitive, safe to output)
- README documenting the manual bootstrap steps below (things Terraform deliberately doesn't do)

### Bootstrap steps (manual, documented in the module's README, not automated)
1. `terraform apply` (using the root token via `VAULT_TOKEN` for this one-time run, reasonable for a low-frequency, human-run apply, same trust level as today's root-equivalent AWS creds in `secrets.yml`)
2. Generate the AppRole secret_id: `vault write -f auth/approle/role/ansible/secret-id`, store the result alongside `role_id` (from Terraform output) as two new keys in the existing `secrets.yml` (`vault_ansible_role_id`, `vault_ansible_secret_id`); reuses the existing gitignored-secrets mechanism rather than inventing a new one
3. Create the human userpass login: `vault write auth/userpass/users/<name> password=... policies=ec2-admin`
4. Migrate secret data: one-time `vault kv put` calls grouped to mirror `secrets.yml`'s existing comment sections (`ec2/aws-creds`, `ec2/duo`, `ec2/users`, `ec2/vhosts`, `ec2/mail`)

### Ansible integration
- Add `community.hashi_vault` to `requirements.yml` (collections)
- **No role changes needed.** Replace the static values in `inventory/group_vars/aws.yml` with `community.hashi_vault.vault_kv2_get` lookups under the *same* variable names (`ec2_users`, `apache_certs`, etc., authenticating via the AppRole `role_id`/`secret_id` from `secrets.yml`); every role still just reads `{{ ec2_users }}` as before, only the source changes from a static file to a live Vault lookup.
- **Rollout safety:** keep `secrets.yml`'s current EC2 values in place as a fallback during transition; don't delete them until the Vault-lookup path has been verified working end-to-end. Remove the fallback only after that's confirmed, as a separate, later cleanup step.

## Addendum: Terraform reading (not writing) a secret (2026-07-12)

Decision #1 above ("Terraform manages structure only, never secret values") is about Terraform never *creating or managing* secret content as a resource. It doesn't preclude Terraform *reading* an already-existing secret via a `vault` provider data source to consume it during provisioning, e.g. `terraform/aws` reading the edge node's SSH bootstrap public key (`ec2/ssh-edge-bootstrap-public`, see `docs/howtos/ec2-rebuild-plan.md`) into an `aws_key_pair` resource. That's a read, not a write; Terraform still never puts anything into Vault.

The caveat: a `vault_kv_secret_v2` data source's entire `data` map lands in Terraform state, not just whatever fields you reference in `.tf` code, so any secret co-located at the same path as something Terraform reads leaks into that state file too. This is why the SSH bootstrap keypair is split into two separate Vault paths (`...-public` / `...-private`) rather than one entry with both fields: Terraform only ever reads the public one, so the private key never touches `terraform/aws`'s state.

## Addendum: Workstation secrets, three-path SSH layout (2026-07-19)

`workstation/` is used across multiple machines (WSL2 home, macOS work laptop, EC2 edge
node), each needing a different subset of SSH hosts and keys, never all keys copied to
all machines. Three-path layout:

- `workstation/ssh-config/<machine>`: one path per machine (keyed by `ansible_hostname`,
  or `inventory_hostname` for remote targets like the EC2 edge node), holding that
  machine's list of SSH host entries. Each entry references a `key_name` (and a
  `key_scope`, see below), not a literal local path.
- `workstation/ssh-keys/generic/<key-name>`: the shared key pool, for keys meant to be
  referenced from more than one machine's config.
- `workstation/ssh-keys/hosts/<machine>/<key-name>`: keys strictly scoped to one
  machine. Lets OpenSSH's own default-identity filenames (e.g. `id_ed25519`) be reused
  across machines without colliding; the generic pool is shared, so two machines both
  storing a key literally named `id_ed25519` there would overwrite each other; the
  per-machine namespace here avoids that entirely.

`roles/configure_ssh-client` reads a machine's config first, then for each entry fetches
its key from whichever pool that entry's `key_scope` (`generic`, the default, or `host`)
points at, so a given machine only ever gets the keys its own config actually needs, not
the whole pool. The *local* filename (`~/.ssh/<key_name>`) is identical either way, only
the Vault source path differs. See the role's own README for the exact schema.

## Addendum: DKIM key backup and Route53 publishing (2026-07-26)

`roles/setup_email-server` generates DKIM key pairs on the mail server itself
(`rspamadm dkim_keygen`, never leaves the box) and every run now also writes:
- `ec2/dkim-private/<domain>` (`private_key`): disaster-recovery backup only, never
  read by Terraform.
- `ec2/dkim-public/<domain>` (`public_key`, the full chunked DKIM TXT value): read by
  `terraform/aws` (`data "vault_kv_secret_v2" "dkim_public"`) to publish the actual
  Route53 `*._domainkey.<domain>` TXT record.

Same public/private split rationale as the addendum above (a `vault_kv_secret_v2` data
source's whole `data` map lands in Terraform state); Terraform only ever reads the
`-public` path, so the private key never touches `terraform/aws` state. Terraform
remains the *only* thing that calls the Route53 API for any record type; Ansible's role
here is limited to generating the key and publishing its derived value to Vault. This
replaced an earlier flow where the public key was printed to the Ansible console for a
human to hand-copy into `terraform.tfvars`, the manual hop that caused a real drift
incident (a rotated key never got copied over, so Route53 kept serving a stale DKIM
record). A `terraform apply` in `terraform/aws` is still required after a rotation to
actually publish the new value, smaller and safer than before (no editing/formatting),
but not fully zero-touch.

## Deferred (explicitly out of scope, tracked for later)
- OIDC auth via Authentik for human login
- MikroTik/router credentials: staying in vaulted `secrets.yml` deliberately (bootstrapping risk)
- Secret rotation automation

## Addendum: Kubernetes SealedSecrets → Vault pilot (2026-09-06)

Piloted on one secret (OpenCloud's admin password) to measure the real effort of
migrating all 49 SealedSecrets currently in `kube-gitops/`, per a request to gauge this
before committing to the full migration.

**Tool: External Secrets Operator (ESO), not Vault Agent Injector.** ESO produces native
`Secret` objects other resources reference normally (`secretKeyRef`, same as
SealedSecrets does today); Vault Agent Injector is sidecar-based and file-mounted, a
bigger blast radius per-Deployment and the older of the two approaches (HashiCorp's own
current guidance favors ESO/Vault Secrets Operator).

**Auth method: AppRole, not Kubernetes auth.** The idiomatic ESO-on-Vault pattern is the
Kubernetes auth method (Vault validates a pod's ServiceAccount token against the
cluster's own API server, no bootstrap secret needed at all). Not viable here: Vault
sits on the EC2 edge node (public internet), the k8s cluster sits on the home LAN behind
NAT, and Kubernetes auth needs Vault to reach *back into* the cluster's API server for
token validation, a path that doesn't exist without the still-unbuilt
`configure_wireguard` role. AppRole works today with no network changes, at the cost of
one small bootstrap secret per cluster (ESO's own `role_id`/`secret_id`) that can't
itself move to Vault, everything else now can. Revisit Kubernetes auth once Wireguard
connects EC2 to the home LAN.

**New Terraform (`terraform/vault/main.tf`):** one `homelab` KV v2 mount (path
convention `homelab/<cluster>/<app>`, e.g. `homelab/k8s/opencloud`, so both clusters
share one mount rather than one per cluster), a `homelab-eso-read` policy (read+list
only, bound to a new `eso-homelab` AppRole role), and a `homelab-admin` policy
(full CRUD, added to the existing human userpass login alongside `ec2-admin`/
`workstation-admin`). Applying this needed the root token, same as the original EC2/
Ansible bootstrap; day-to-day `vault kv put` work under `homelab-admin` doesn't.

**New Kubernetes-side pieces (per cluster, one-time):**
- `external-secrets` app: the ESO Helm chart itself
- `external-secrets-config` app: the `ClusterSecretStore` pointing at Vault, plus the
  one bootstrap `SealedSecret` holding ESO's AppRole `secret_id`
- Per-secret, going forward: one `ExternalSecret` manifest replaces one `SealedSecret`
  manifest, same target `Secret` name/key, so nothing consuming the secret needs to
  change

**Gotchas hit:**
- Two of ESO's CRDs (`clustersecretstores.external-secrets.io`,
  `secretstores.external-secrets.io`) exceed the 262KB `kubectl.kubernetes.io/
  last-applied-configuration` annotation limit under client-side apply, same issue
  already documented for CNPG in `CLAUDE.md`'s Known Gotchas. Fix: `ServerSideApply=true`
  in the app's `syncOptions`.
- SealedSecrets' controller refuses to adopt a pre-existing plain `Secret` it didn't
  create ("already exists and is not managed by SealedSecret"); had to delete the plain
  Secret first and let the controller recreate it. ESO's `ExternalSecret` did not have
  this problem, it took over and updated the existing Secret in place without complaint.
- An in-flight ArgoCD sync operation retries with the `syncOptions` it was *created*
  with, not the current ones from git; patching `.spec` isn't enough to make a stuck
  retry loop pick up a fix. Needed `argocd app terminate-op` (via `argocd login --core`,
  no separate ArgoCD login required) to actually cancel it before a fresh sync would use
  the corrected options.

**Effort measured:** roughly a day's work end to end for the first secret, most of it
one-time cost (Terraform module changes, ESO installation, the CRD/ArgoCD gotchas
above). Each *additional* secret after that is a much smaller, mechanical change: delete
one `SealedSecret` manifest, add one `ExternalSecret` manifest pointing at a new
`homelab/<cluster>/<app>` path, `vault kv put` the value once. No changes needed to
whatever actually consumes the secret. Extrapolating: migrating the remaining ~48
SealedSecrets is a series of small, low-risk, repeatable PRs, not a re-run of this
one-time setup cost.

**Result:** confirmed working end to end on k8s. Pod never restarted during the
migration (env vars are read once at container start, so replacing the backing Secret
object doesn't disrupt an already-running pod); the resolved value matched exactly.

## Verification (once implemented)
- `terraform -chdir=terraform/vault plan` / `apply` succeed cleanly against the new module
- `vault policy read ec2-ansible-read` / `vault auth list` confirm the AppRole and policies exist as expected
- A manual `vault write auth/approle/login role_id=... secret_id=...` succeeds and returns a token scoped to `ec2-ansible-read` only (confirm it does NOT have access outside `ec2/*`, try reading a different mount/path and confirm denial)
- An Ansible lookup test resolves `ec2_users`/`apache_certs` via `community.hashi_vault.vault_kv2_get` and matches the current `secrets.yml` values exactly
- `ansible-playbook -i inventory/aws_hosts playbooks/ec2-core.yml --check` (and similarly `ec2-web.yml`, `ec2-vault.yml`) still resolve all EC2 variables correctly once `aws.yml` is switched to Vault-backed lookups
