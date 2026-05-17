---
title: "Authentik User Management"
type: how-to
status: stable
scope: [k8s, k3s]
created: 2026-05-16
updated: 2026-05-16
tags: [authentik, users, sso, idp, runbook]
---

# Authentik User Management

Authentik is the identity provider (IdP) for the k8s cluster. Users created here get SSO access to all
connected apps (Forgejo, and future services).

## Create a user

### Option A — Web UI (simplest)

1. Go to **https://authentik.kecskemethy.org** → log in as `akadmin`
2. **Admin interface** → **Directory** → **Users** → **Create**
3. Fill in: Username, Name, Email → **Create**
4. Open the user → **Set password**

### Option B — CLI via `ak shell`

```bash
kubectl exec -n authentik --context admin@k8s deployment/authentik-worker -- ak shell -c "
import secrets, string
from authentik.core.models import User
pwd = ''.join(secrets.choice(string.ascii_letters + string.digits + '!@#\$%') for _ in range(14))
u, created = User.objects.get_or_create(
    username='alice',
    defaults={'name': 'Alice Example', 'email': 'alice@example.com'}
)
if created:
    u.set_password(pwd)
    u.save()
    print(f'Created user: {u.username}  password: {pwd}')
else:
    print(f'User {u.username} already exists')
"
```

Replace `alice`, `Alice Example`, and `alice@example.com` with the real values.
Share the printed password with the user — they can change it after first login.

## Reset a user's password

### Web UI

Admin interface → **Directory** → **Users** → select user → **Set password**

### CLI

```bash
kubectl exec -n authentik --context admin@k8s deployment/authentik-worker -- \
  ak changepassword <username>
```

## Forgejo account linking

The Authentik → Forgejo OAuth2 source uses `sub_mode: user_username`. This means:

- An Authentik user with username `kecsi` maps to the Forgejo user `kecsi` automatically
- On first OAuth2 login, Forgejo links the accounts if the username matches
- If no Forgejo account exists yet, Forgejo creates one with that username

**Existing Forgejo admin (`kecsi`):** create the Authentik user with the same username
and the accounts will link on the next login via "Sign in with authentik".

## Disable / delete a user

Admin interface → **Directory** → **Users** → select user → **Deactivate** (reversible)
or **Delete** (permanent).

## Notes

- `akadmin` is the bootstrap admin — keep its password in the `authentik-credentials`
  SealedSecret only; do not use it for day-to-day logins
- Regular users should not have Authentik admin access unless they need to manage the IDP
- `DISABLE_REGISTRATION = true` is set in Forgejo; users must be created in Authentik first
