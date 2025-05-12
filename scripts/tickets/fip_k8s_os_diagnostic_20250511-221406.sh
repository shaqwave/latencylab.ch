#!/usr/bin/env bash
# fip_k8s_os_diagnostic_20250511-221406.sh
# Gathers Kubernetes/OpenStack diagnostics for support ticket attachments.

# bash configuration:
set -o nounset
set -o errexit
set -o pipefail

readonly REPORT_FILE="fip_diagnostic_report_$(date +%Y%m%d-%H%M%S).md"
readonly K8S_NS="latencylab-is"
readonly K8S_SVC="latencylab-core-ingress-controller"

function _report_header {
  printf '# Floating IP + Ingress Diagnostic Report\n' > "${REPORT_FILE}"
  printf '_Generated: %s (UTC)_\n\n' "$(date -u)" >> "${REPORT_FILE}"
}

function _section {
  local -r name="${1}"
  printf '\n## %s\n\n' "${name}" >> "${REPORT_FILE}"
}

function _cmd {
  local -r label="${1}"
  local -r cmd="${2}"
  printf '```bash\n# %s\n%s\n\n' "${label}" "${cmd}" >> "${REPORT_FILE}"
  eval "${cmd}" 2>&1 >> "${REPORT_FILE}"
  printf '```\n' >> "${REPORT_FILE}"
}

function _k8s_diagnostics {
  _section '🔍 Kubernetes: Ingress Service'
  _cmd 'Describe ingress svc' "kubectl describe svc ${K8S_SVC} -n ${K8S_NS}"
  _section '📌 Endpoints'
  _cmd 'Get endpoints' "kubectl get ep ${K8S_SVC} -n ${K8S_NS} -o wide"
  _section '🌐 Ingress Resource'
  _cmd 'Describe ingress' "kubectl describe ingress latencylab-redirect -n ${K8S_NS}"
}

function _cert_state {
  _section '🔐 Certificate + Challenges'
  _cmd 'Certificate' "kubectl describe certificate -n ${K8S_NS}"
  _cmd 'Challenge' "kubectl describe challenge -n ${K8S_NS}"
  _cmd 'Order' "kubectl describe order -n ${K8S_NS}"
}

function _secret_decode {
  _section '🔑 ACME Secret'
  _cmd 'acme-dns-credentials decoded' \
    "kubectl get secret acme-dns-credentials -n ${K8S_NS} -o jsonpath=\"{.data['latencylab\\.is']}\" | base64 --decode | jq"
}

function _os_fip {
  _section '🕵️ OpenStack Env'
  _cmd 'OS_*' 'env | grep "^OS_"'
  _section '🌐 FIPs'
  _cmd 'FIP list' 'openstack floating ip list --long'
  _section '🔎 Ports + Instances'
  _cmd 'Port list' 'openstack port list --device-owner compute:nova'
  _cmd 'Server list' 'openstack server list'
}

function main {
  _report_header
  _k8s_diagnostics
  _cert_state
  _secret_decode
  _os_fip
  printf '\n✅ Diagnostic written: %s\n' "${REPORT_FILE}"
}

main
