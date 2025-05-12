#!/usr/bin/env bash
# triage_network_fip_issue_20250511.sh
# Gathers network-related diagnostics for K8s/OpenStack FIP issues into a single Markdown report.

# bash configuration:
# 1) Exit script if you try to use an uninitialized variable.
set -o nounset

# 2) Exit script if a statement returns a non-true return value.
set -o errexit

# 3) Use the error status of the first failure, rather than that of the last item in a pipeline.
set -o pipefail

declare -r k8s_cmds=(
  'kubectl get all -A'
  'kubectl get svc -A'
  'kubectl get ingress -A'
  'kubectl get ingressclass'
  'kubectl get endpoints -A'
  'kubectl get pvc -A'
  'kubectl get secret -A'
)

declare -r os_base_cmds=(
  'env | grep OS_'
  'openstack server list'
  'openstack port list'
  'openstack network list'
  'openstack floating ip list'
)

function main() {
  local -r ts="$(date +%Y%m%d_%H%M%S)"
  local report
  report="$( report_name "${ts}" )"

  printf '# Network Triage Report (%s)\n\n' "${ts}" >"${report}"

  k8s_sections "${report}"
  openstack_sections "${report}"
  # k8s_secrets_sections "${report}"

  printf '✅  Report generated: %s\n' "${report}"
}

function k8s_sections() {
  local -r report="${1}"
  render_section "Kubernetes Resources" >>"${report}"
  for cmd in "${k8s_cmds[@]}"; do
    render_cmd_output "${cmd}" >>"${report}" || true
  done
}

function k8s_secrets_sections() {
  local -r report="${1}"
  render_section "Redacted Secrets (Kubernetes)" >>"${report}"
  local secrets_raw
  secrets_raw="$(kubectl get secret -A -o json 2>&1 || true)"
  printf '## kubectl get secret -A -o json (stderr)\n\n```text\n%s\n```\n\n' "${secrets_raw}" >>"${report}"

  if command -v jq >/dev/null; then
    local secrets_masked
    secrets_masked=$(jq 'del(.items[].data, .items[].stringData)' <<<"${secrets_raw}" 2>/dev/null || true)
    printf '## Redacted Secret Dump\n\n```json\n%s\n```\n' "${secrets_masked}" >>"${report}"
  fi

}

function openstack_sections() {
  local -r report="${1}"
  render_section "OpenStack Resources" >>"${report}"

  local os_regions
  os_regions=$(openstack region list -f value -c Region  2> /dev/null | grep -vi billing || echo "$OS_REGION_NAME")

  for region in ${os_regions}; do
    render_subsection "Region: ${region}" >>"${report}"
    for cmd in "${os_base_cmds[@]}"; do
      (
        export OS_REGION_NAME="${region}"
        render_cmd_output "${cmd}" >>"${report}" || true
      )
    done
  done
}

function report_name() {
  local -r ts="${1}"
  local -r out_dir="$(git rev-parse --show-toplevel)/scripts/tickets/reports"
  mkdir -p "${out_dir}"
  local -r report="${out_dir}/triage_fip_network_${ts}.md"
  printf '%s' "${report}"
}

function render_section() {
  local -r title="${1}"
  printf '\n# %s\n\n' "${title}"
}

function render_subsection() {
  local -r title="${1}"
  printf '\n## %s\n\n' "${title}"
}

function redact_shit() {
    sed -e 's|\x1b\[[0-9;]*m||g' \
    | sed -e '/Readline features including tab completion have been disabled because/,/Mac\./d' \
    | sed -e 's|OS_PASSWORD=.*|OS_PASSWORD=REDACTED|g'
}

function render_cmd_output() {
  local -r cmd="${1}"
  local out err
  eval "${cmd}" > /tmp/stdout.$$ 2>/tmp/stderr.$$ || true
  out="$(redact_shit < /tmp/stdout.$$)"
  err="$(redact_shit < /tmp/stderr.$$)"
  rm -f /tmp/stderr.$$ /tmp/stdout.$$ || true
  [[ -n "${out}" ]] && printf '### %s (stdout)\n\n```text\n%s\n```\n\n' "${cmd}" "${out}"
  [[ -n "${err}" ]] && printf '### %s (stderr)\n\n```text\n%s\n```\n\n' "${cmd}" "${err}"
}

main "$@"
