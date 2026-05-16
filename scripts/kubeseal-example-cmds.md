# kubeseal example commands

## Authentik secrets

### Secret 1 — postgres namespace (CNPG managed role password)

```bash
AUTHDBPASS="$(openssl rand -base64 24)"
AUTHADMINPASS="$(openssl rand -base64 16)"
AUTHSECRETKEY="$(openssl rand -base64 60 | tr -d '\n')"
kubectl create secret generic authentik-db-credentials --namespace postgres \
  --from-literal=username=authentik \
  --from-literal=password="$AUTHDBPASS" --dry-run=client -o yaml | \
  kubeseal --format yaml \
    --context "admin@k8s" \
    --controller-name sealed-secrets \
    --controller-namespace sealed-secrets
```

### Secret 2 — authentik namespace (app credentials)

```bash
kubectl create secret generic authentik-credentials --namespace authentik \
  --from-literal=secret-key="$AUTHSECRETKEY" \
  --from-literal=postgresql-password="$AUTHDBPASS" \
  --from-literal=bootstrap-password="$AUTHADMINPASS" \
  --from-literal=bootstrap-email=kecskemethy@gmail.com --dry-run=client -o yaml | \
  kubeseal --format yaml \
    --context "admin@k8s" \
    --controller-name sealed-secrets \
    --controller-namespace sealed-secrets
```

## Forgejo <-> Authentik integration secrets
### Generate a client secret first

```bash
FORG_CLIENT_SECRET=$(openssl rand -base64 32 | tr -d '\n')
echo $FORG_CLIENT_SECRET
```

### Secret 1 — authentik namespace (blueprint reads via env var)

```bash
kubectl create secret generic authentik-forgejo-oauth2 --namespace authentik \
  --from-literal=client-secret="${FORG_CLIENT_SECRET}" --dry-run=client -o yaml | \
  kubeseal --format yaml \
    --context "admin@k8s" \
    --controller-name sealed-secrets \
    --controller-namespace sealed-secrets
```

### Secret 2 — forgejo namespace (Job reads to register the source)

```bash
kubectl create secret generic forgejo-authentik-oauth2 --namespace forgejo \
  --from-literal=client-secret="${FORG_CLIENT_SECRET}" --dry-run=client -o yaml | \
  kubeseal --format yaml \
    --context "admin@k8s" \
    --controller-name sealed-secrets \
    --controller-namespace sealed-secrets
```
