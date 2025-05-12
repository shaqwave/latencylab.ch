#!/usr/bin/env bash
# setup_acme_manual_dns.sh
# Prerequisite setup for cert-manager manual DNS-01: generate ACME key and create required secret.

# bash configuration:
# 1) Exit script if you try to use an uninitialized variable.
set -o nounset
# 2) Exit script if a statement returns a non-true return value.
set -o errexit
# 3) Use the error status of the first failure, rather than that of the last item in a pipeline.
set -o pipefail

readonly ACME_SECRET_NAME='letsencrypt-dns-key'
readonly ACME_SECRET_NAMESPACE='cert-manager'
readonly ACME_KEY_FILE='/tmp/manual-dns-acme.key'

function main() {
  local -r commit_flag="${1:-}"
  _generate_key
  _ensure_namespace
  _create_secret "${commit_flag}"
  printf '✅ ACME secret setup complete.\n'
}

function _generate_key() {
  printf '🔐 Generating private key...\n'
  rm -f "${ACME_KEY_FILE}" || true
  openssl genrsa -out "${ACME_KEY_FILE}" 4096 >/dev/null 2>&1
}

function _ensure_namespace() {
  if ! kubectl get ns "${ACME_SECRET_NAMESPACE}" >/dev/null 2>&1; then
    printf '⚙️  Creating namespace: %s\n' "${ACME_SECRET_NAMESPACE}"
    kubectl create ns "${ACME_SECRET_NAMESPACE}" >/dev/null
  fi
}

function _create_secret() {
  local -r commit_flag="$1"
  printf '📦 Preparing secret: %s (namespace: %s)\n' "${ACME_SECRET_NAME}" "${ACME_SECRET_NAMESPACE}"
  if [[ "${commit_flag}" != '--commit' ]]; then
    printf '🛑 Dry run only. Run again with --commit to apply changes.\n'
    kubectl create secret generic "${ACME_SECRET_NAME}" \
      --from-file=private-key.pem="${ACME_KEY_FILE}" \
      -n "${ACME_SECRET_NAMESPACE}" \
      --dry-run=client -o yaml
    exit 0
  fi
  kubectl create secret generic "${ACME_SECRET_NAME}" \
    --from-file=private-key.pem="${ACME_KEY_FILE}" \
    -n "${ACME_SECRET_NAMESPACE}" \
    --dry-run=client -o yaml | kubectl apply -f -
}

main "$@"
