#!/usr/bin/env bash
# Looks up the Cloudflare zone ID for a domain and prints the secrets.yml snippet.
# Usage: ./scripts/cloudflare-zone-id.sh <api-token> [domain]
# If domain is omitted, reads domain_name from inventory/group_vars/all/vars.yml.

set -euo pipefail

API_TOKEN="${1:-}"
if [[ -z "$API_TOKEN" ]]; then
  echo "Usage: $0 <cloudflare-api-token> [domain]" >&2
  exit 1
fi

if [[ -n "${2:-}" ]]; then
  DOMAIN="$2"
else
  VARS_FILE="$(dirname "$0")/../inventory/group_vars/all/vars.yml"
  DOMAIN=$(grep 'domain_name:' "$VARS_FILE" | awk '{print $2}' | tr -d '"')
  if [[ -z "$DOMAIN" ]]; then
    echo "Could not read domain_name from $VARS_FILE — pass it as second argument." >&2
    exit 1
  fi
fi

RESPONSE=$(curl -sf \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "Content-Type: application/json" \
  "https://api.cloudflare.com/client/v4/zones?name=${DOMAIN}")

ZONE_ID=$(echo "$RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['result'][0]['id'])" 2>/dev/null || true)

if [[ -z "$ZONE_ID" ]]; then
  echo "Zone not found for domain '$DOMAIN'. Check your token has Zone:Read scope." >&2
  exit 1
fi

echo "# Add to inventory/group_vars/all/secrets.yml:"
echo "cloudflare_api_token: \"$API_TOKEN\""
echo "cloudflare_zone_id: \"$ZONE_ID\""
