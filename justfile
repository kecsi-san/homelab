# justfile — single entry point for common repo commands.
# See CLAUDE.md "Common Commands" for the source-of-truth prose this mirrors.
#
# Usage: `just --list` to see all recipes, `just <recipe>` to run one.

set shell := ["bash", "-uc"]

default:
    @just --list

# ---- Setup ----

# Install Python dependencies (ansible-core, cryptography, jmespath, etc.)
setup-pip:
    pip install -r requirements.txt

# Install required Ansible Galaxy collections/roles (incl. Kubespray)
setup-galaxy:
    ansible-galaxy install -r requirements.yml

# Run both setup steps
setup: setup-pip setup-galaxy

# ---- Local workstation ----

# Core system setup (brew, apt repos, minimal, network, python-uv)
local-core:
    ansible-playbook playbooks/local-core.yml

# Security hardening (sudo, duosecurity repo, fail2ban, rkhunter, lynis, trivy)
local-security:
    ansible-playbook playbooks/local-security.yml

# Developer tooling (vscode, go, nodejs, rust) — run after local-core
local-dev:
    ansible-playbook playbooks/local-dev.yml

# Cloud/DevOps tooling (terraform, iac-extra, aws, azure, gcp) — run after local-core
local-cloud:
    ansible-playbook playbooks/local-cloud.yml

# Kubernetes tooling (kubectl, helm, argocd, flux, kubeseal) — run after local-core
local-kube:
    ansible-playbook playbooks/local-kube.yml

# Taste-driven setup (fonts, shell prompt, wallpapers, profile image)
personalise:
    ansible-playbook playbooks/personalise.yml

# Upgrade local workstation packages (apt, brew, uv)
upgrade-local:
    ansible-playbook playbooks/upgrade-local.yml

# ---- Kubernetes cluster (Kubespray, bare metal) ----

# Prerequisite SSH/sudo setup — required once before k8s-nodes.yml
prerequisite:
    ansible-playbook --ask-become-pass playbooks/prerequisite.yml

# Mirrors local-core.yml but targets the kube group (remote hosts)
k8s-nodes:
    ansible-playbook playbooks/k8s-nodes.yml

# Pre-Kubernetes node preparation (etckeeper etc.)
pre-k8s:
    ansible-playbook playbooks/pre-k8s.yml

# Install the Kubernetes cluster (delegates to Kubespray)
k8s:
    ansible-playbook -b playbooks/k8s.yml

# Reset/tear down the Kubernetes cluster (delegates to Kubespray)
reset-k8s:
    ansible-playbook playbooks/reset-k8s.yml

# Gracefully shut down the whole cluster (drain PVC-backed pods, then power off all nodes)
shutdown-k8s:
    ansible-playbook playbooks/shutdown-k8s.yml

# Manual fallback to uncordon all nodes (normally automatic a few minutes after boot)
uncordon-k8s:
    ansible-playbook playbooks/uncordon-k8s.yml

# Post-Kubernetes setup (Longhorn storage, Traefik, etc.)
post-k8s:
    ansible-playbook playbooks/post-k8s.yml

# OS package upgrades across all kube group hosts
upgrade:
    ansible-playbook playbooks/upgrade.yml

# ---- k3s (single-node local dev cluster) ----

# Install k3s
k3s:
    ansible-playbook playbooks/k3s.yml

# Uninstall k3s
reset-k3s:
    ansible-playbook playbooks/reset-k3s.yml

# Post-k3s setup (Traefik, Sealed Secrets, ArgoCD, GitOps bootstrap)
post-k3s:
    ansible-playbook playbooks/post-k3s.yml

# ---- Router / DNS ----

# Upsert MikroTik DNS/NAT rules — run before k8s.yml and after changing LB IPs/domain/port forwards
configure-router:
    ansible-playbook playbooks/configure-router.yml

# Configure Cloudflare zone settings and DNS records
configure-cloudflare:
    ansible-playbook playbooks/configure-cloudflare.yml

# ---- Fileservers ----

# Baseline prerequisites/hardening + shell comfort + app-specific tooling for fileservers group
fileservers:
    ansible-playbook playbooks/fileservers.yml

# Carve NFS backup share + restic REST server on hppd600g6
backup-nfs:
    ansible-playbook playbooks/backup-nfs.yml

# ---- AWS EC2 edge node ----

# First-time setup (passwordless sudo not yet configured)
ec2-prerequisite:
    ansible-playbook --ask-become-pass -i inventory/aws_hosts playbooks/ec2-prerequisite.yml

# Base hardening — run after ec2-prerequisite
ec2-core:
    ansible-playbook -i inventory/aws_hosts playbooks/ec2-core.yml

# Web server (Apache2 + ModSecurity + ModEvasive + certbot) — run after ec2-core
ec2-web:
    ansible-playbook -i inventory/aws_hosts playbooks/ec2-web.yml

# Email server (Postfix + Dovecot + Rspamd + OpenDMARC + certbot) — run after ec2-web
ec2-mail:
    ansible-playbook -i inventory/aws_hosts playbooks/ec2-mail.yml

# HashiCorp Vault — run after ec2-web; manually init+unseal after first deploy
ec2-vault:
    ansible-playbook -i inventory/aws_hosts playbooks/ec2-vault.yml

# ---- Terraform (AWS) ----

# Initialise the AWS terraform backend
terraform-init:
    cd terraform/aws && terraform init -backend-config=backend.conf

# Show the terraform plan
terraform-plan:
    cd terraform/aws && terraform plan

# Apply the terraform plan
terraform-apply:
    cd terraform/aws && terraform apply

# Import an existing EC2 instance
terraform-import-instance instance_id:
    cd terraform/aws && terraform import aws_instance.ec2 {{instance_id}}

# Import an existing Elastic IP allocation
terraform-import-eip allocation_id:
    cd terraform/aws && terraform import aws_eip.ec2 {{allocation_id}}

# Import an existing Route53 zone (domain e.g. kecskemethy.com, plus its zone ID)
terraform-import-zone domain zone_id:
    cd terraform/aws && terraform import 'aws_route53_zone.zones["{{domain}}"]' {{zone_id}}

# ---- Ansible helpers ----

# Dry run a playbook (--check mode)
check playbook:
    ansible-playbook --check {{playbook}}

# Syntax-check a playbook
syntax-check playbook:
    ansible-playbook --syntax-check {{playbook}}

# Run a playbook restricted to specific tags, e.g. `just tags playbooks/local-core.yml minimal,brew`
tags playbook tags:
    ansible-playbook -t {{tags}} {{playbook}}

# ---- Lint (mirrors .github/workflows/lint.yml) ----

# Run yamllint across the repo
lint-yaml:
    yamllint .

# Run ansible-lint (requires Ansible Vault password file, see ansible.cfg vault_password_file)
lint-ansible:
    ansible-lint

# Run all lint checks
lint: lint-yaml lint-ansible

# ---- Full cluster rebuild runbook ----
# Mirrors CLAUDE.md's "Full cluster rebuild runbook" steps 1-4.
# Steps 5-7 (sealed-secrets key restore, Firefox HSTS cache clear, Longhorn smoke
# test) are manual/interactive and printed as a reminder at the end, not automated.

# Rebuild the whole k8s cluster from scratch: configure-router -> reset-k8s -> k8s -> post-k8s
rebuild-k8s: configure-router reset-k8s k8s post-k8s
    @echo ""
    @echo "Automated steps done. Remaining manual steps (see CLAUDE.md):"
    @echo "  5. kubectl apply -f ~/sealed-secrets-key-backup.yaml"
    @echo "     kubectl rollout restart deployment sealed-secrets -n sealed-secrets"
    @echo "     # ArgoCD will reconcile; rollout restart any pods stuck in ContainerCreating"
    @echo "     # once their SealedSecrets are decrypted"
    @echo "  6. Firefox HSTS: delete SiteSecurityServiceState.bin from the Firefox profile"
    @echo "     folder (about:support -> Open Profile Folder) to clear stale HSTS state"
    @echo "  7. Verify Longhorn storage (see CLAUDE.md for the full kubectl run one-liner)"
