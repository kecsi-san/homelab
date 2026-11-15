#!/usr/bin/env bash
# Print the Microsoft consumer mail domains (Outlook.com / Hotmail / Live / MSN and their
# country variants), one per line, to route through a smarthost.
#
# A domain counts when its lowest-preference MX is in Microsoft's consumer mail system:
#   *.olc.protection.outlook.com  (Outlook.com consumer filtering, where the S3150 block lives)
#   *.mx.microsoft                (newer consumer MX hosts used by a few country variants)
# Domains with a third-party MX (outlook.co.uk) or no MX (live.hu) are left out on purpose.
#
# Usage:  scripts/ms-consumer-domains.sh [resolver] > roles/configure_postfix-smarthost/files/microsoft-consumer-domains.txt
# Needs:  dig. The resolver defaults to 1.1.1.1; the lookups are public DNS only.
set -euo pipefail

resolver="${1:-1.1.1.1}"

fixed=(msn.com passport.com windowslive.com)
brands=(hotmail outlook live)
tlds=(com at be ca ch cl cn co.jp co.uk com.au com.br com.mx com.pt cz de dk es fi fr gr hk hu ie
      it jp nl no pt ru se sk)

candidates=("${fixed[@]}")
for b in "${brands[@]}"; do
  for t in "${tlds[@]}"; do
    candidates+=("$b.$t")
  done
done

for d in $(printf '%s\n' "${candidates[@]}" | sort -u); do
  mx="$(dig +short +time=3 +tries=2 MX "$d" @"$resolver" | sort -n | awk 'NR==1 {print $2}')"
  case "$mx" in
    *.olc.protection.outlook.com. | *.mx.microsoft.) echo "$d" ;;
  esac
done
