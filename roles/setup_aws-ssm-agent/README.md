# setup_aws-ssm-agent

Installs and enables the AWS Systems Manager (SSM) agent, giving an out-of-band rescue path (AWS Console → Session Manager) that doesn't depend on sshd — useful before making risky SSH/PAM config changes.

## What it does

- Downloads the region-specific `amazon-ssm-agent.deb` package
- Installs it via `apt`
- Enables and starts the `amazon-ssm-agent` systemd service

## Variables

| Variable | Default | Description |
|----------|---------|--------------|
| `aws_ssm_region` | `eu-west-1` | AWS region the EC2 instance runs in; used to build the download URL |

## Prerequisites

The EC2 instance's IAM instance profile must have a role with the `AmazonSSMManagedInstanceCore` managed policy attached, or the agent will install and run but never register with Systems Manager. This is not managed by Ansible — attach it manually or via Terraform IAM resources:

```bash
aws iam attach-role-policy --role-name <role-name> \
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
```

## Verification

```bash
aws ssm describe-instance-information
```

Confirm the instance shows `PingStatus: Online`.

## Usage

```yaml
- name: Setup AWS SSM agent
  ansible.builtin.import_role:
    name: setup_aws-ssm-agent
  tags:
    - ssm
```
