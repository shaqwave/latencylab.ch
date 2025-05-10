#!/bin/bash
# infomaniak_redirect_o11y.sh
# Observability script: DIG and CURL each subdomain and show redirect behavior

set -o nounset
set -o errexit
set -o pipefail

DOMAINS=(
  www101.shaqwave.co
  www102.shaqwave.co
  www103.shaqwave.co
  www104.shaqwave.co
  www105.shaqwave.co
  www106.shaqwave.co
  www107.shaqwave.co
  www108.shaqwave.co
  www109.shaqwave.co
  www110.shaqwave.co
  www111.shaqwave.co
)

for name in "${DOMAINS[@]}"; do
  echo "🔍 $name"
  echo "🔹 dig TXT:"
  dig +short TXT "${name}"

  echo "🔹 curl -vv:"
  curl -s -o /dev/null -w "%{http_code}\n" -L "${name}" || true
  curl -s -vv "${name}" 2>&1 \
    | grep -Ei '^(< HTTP|< Location:|> GET )' \
    || echo "(no redirect or iframe fallback)"

  echo "--------------------------------------------------"
done

