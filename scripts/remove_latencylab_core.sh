#!/usr/bin/env bash
# scripts/tickets/remove_latencylab_core.sh
# Uninstalls Helm release and K8s resources (default: dry-run, real if --commit passed).

# bash configuration:
# 1) Exit script if you try to use an uninitialized variable.
set -o nounset

# 2) Exit script if a statement returns a non-true return value.
set -o errexit

# 3) Use the error status of the first failure, rather than that of the last item in a pipeline.
set -o pipefail

function main() {
  local -r ns='latencylab-is'
  local -r commit="${1:-}"
  [[ "${commit}" == '--commit' ]] && _do || _preview
}

function _do() {
  helm uninstall latencylab-core --namespace latencylab-is || true
  kubectl delete namespace latencylab-is --wait=true || true
  _delete_namespace_if_exists ingress-nginx
  _delete_pvcs
  _delete_secrets
  _show_lbs
  _delete_ingressclass_if_exists nginx
  _delete_crds_matching 'cert-manager\|ingress'
  printf '✅ Deleted Helm release, namespace, and residuals.\n'
}

function _preview() {
  printf '🔍 Dry-run mode. Use --commit to apply changes.\n\n'
  printf 'Would uninstall Helm release and namespace:\n\n'
  printf '  helm uninstall latencylab-core --namespace latencylab-is\n'
  printf '  kubectl delete namespace latencylab-is --wait=true\n'
  printf '  (if exists) kubectl delete namespace ingress-nginx --wait=true\n\n'
  _delete_pvcs dry
  _delete_secrets dry
  _show_lbs
}

function _delete_ingressclass_if_exists() {
  local -r name="${1}"
  kubectl get ingressclass "${name}" &>/dev/null && \
    kubectl delete ingressclass "${name}" || true
}

function _delete_crds_matching() {
  local -r pattern="${1}"
  kubectl get crd -o name | grep -E "${pattern}" | while read -r crd; do
    kubectl delete "${crd}" || true
  done
}

function _delete_namespace_if_exists() {
  local -r ns="${1}"
  kubectl get ns "${ns}" &>/dev/null && kubectl delete ns "${ns}" --wait=true || true
}

function _delete_pvcs() {
  local dry="${1:-}"
  kubectl get pvc -A --no-headers 2>/dev/null \
    | awk '$1 == "latencylab-is" {print $2}' \
    | while read -r pvc; do
        [[ "${dry}" == 'dry' ]] && printf '  kubectl delete pvc %s -n latencylab-is\n' "${pvc}" || \
        kubectl delete pvc "${pvc}" -n latencylab-is || true
      done
}

function _delete_secrets() {
  local dry="${1:-}"
  kubectl get secret -n latencylab-is --no-headers 2>/dev/null \
    | awk '{print $1}' \
    | while read -r s; do
        [[ "${dry}" == 'dry' ]] && printf '  kubectl delete secret %s -n latencylab-is\n' "${s}" || \
        kubectl delete secret "${s}" -n latencylab-is || true
      done
}

function _show_lbs() {
  printf '\nOpenStack load balancers (if any):\n\n'
  openstack loadbalancer list --long 2>/dev/null | grep latencylab || true
}

main "${1:-}"
