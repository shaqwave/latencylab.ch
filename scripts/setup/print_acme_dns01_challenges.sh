#!/usr/bin/env bash
# scripts/print_acme_dns01_challenges.sh
# Print required DNS-01 ACME challenge TXT records from cert-manager.

# bash configuration:
# 1) Exit script if you try to use an uninitialized variable.
set -o nounset
# 2) Exit script if a statement returns a non-true return value.
set -o errexit
# 3) Use the error status of the first failure, rather than that of the last item in a pipeline.
set -o pipefail

function main() {
  local -r ns="${1:-latencylab-is}"
  local -a challenges
  challenges=($(kubectl get challenges.acme.cert-manager.io -n "${ns}" \
    -o jsonpath='{range .items[?(@.status.presented==false)]}{"__"}{.spec.dnsName}{"|"}{.spec.token}{"|"}{.spec.key}{"\n"}{end}' || true))
  if [[ "${#challenges[@]}" -eq 0 ]]; then
    printf '✅ No pending DNS-01 challenges found.\n'
    return
  fi
  printf '🛠 Required DNS TXT records:\n\n'
  for item in "${challenges[@]}"; do
    IFS='|' read -r host token key <<<"${item#__}"
    printf '  Host: _acme-challenge.%s\n' "${host}"
    printf '  Type: TXT\n'
    printf '  Value: %s\n\n' "${key}"
  done
}

main "${1:-}"
