#!/usr/bin/env bash
# dns-delegate-acme.sh — Checks if _acme-challenge TXT exists in current zone and emits setup instructions

# bash configuration:
# 1) Exit script if you try to use an uninitialized variable.
set -o nounset
# 2) Exit script if a statement returns a non-true return value.
set -o errexit
# 3) Use the error status of the first failure, rather than that of the last item in a pipeline.
set -o pipefail

readonly ACME_HOST='_acme-challenge.latencylab.is'

function main() {
  require::command 'dig'
  check::acme_txt
}

function require::command() {
  local -r cmd="$1"
  command -v "${cmd}" >/dev/null 2>&1 || {
    printf '❌ Required command not found: %s\n' "${cmd}" >&2
    exit 1
  }
}

function check::acme_txt() {
  printf '🔎 Checking for existing TXT record at %s...\n' "${ACME_HOST}"
  local result
  result="$(dig +short TXT "${ACME_HOST}" | tr -d '"')"

  if [[ -n "${result}" ]]; then
    printf '✅ Existing TXT record found: %s\n' "${result}"
  else
    printf '⚠️  No TXT record found for %s\n' "${ACME_HOST}"
    printf '\n📌 Manual setup required. Please refer to:\n'
    printf '  docs/20-1984-freedns.md\n'
    printf '\nExample TXT format:\n'
    printf '  _acme-challenge.latencylab.is. IN TXT "<token>"\n'
  fi
}

main "$@"
