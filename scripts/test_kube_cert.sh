#!/usr/bin/env bash
# test_kube_cert.sh — Decode and test TLS cert auth from current kubeconfig

set -euo pipefail

readonly KUBECFG="${KUBECONFIG:-$HOME/.kube/config}"
readonly TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

printf '🔍 Using kubeconfig: %s\n' "$KUBECFG"

# Extract and decode cert/key/ca
yq() { /usr/bin/env yq eval "$@" "$KUBECFG"; }

base64_decode() {
  base64 -D 2>/dev/null || base64 -d
}

yq '.users[0].user["client-certificate-data"]' | tr -d '"' | base64_decode > "$TMPDIR/client.crt"
yq '.users[0].user["client-key-data"]' | tr -d '"' | base64_decode > "$TMPDIR/client.key"
yq '.clusters[0].cluster["certificate-authority-data"]' | tr -d '"' | base64_decode > "$TMPDIR/ca.crt"
readonly API_SERVER="$(yq '.clusters[0].cluster.server' | tr -d '"')"

printf '📡 Target API server: %s\n' "$API_SERVER"

# Test raw curl connection
echo
curl --cert "$TMPDIR/client.crt" \
     --key "$TMPDIR/client.key" \
     --cacert "$TMPDIR/ca.crt" \
     --silent --show-error --write-out '\nHTTP %{http_code}\n' \
     "$API_SERVER/"
