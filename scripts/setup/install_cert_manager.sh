#!/usr/bin/env bash
# install_cert_manager.sh
# Install cert-manager and CRDs into the Kubernetes cluster.

# bash configuration:
# 1) Exit script if you try to use an uninitialized variable.
set -o nounset
# 2) Exit script if a statement returns a non-true return value.
set -o errexit
# 3) Use the error status of the first failure, rather than that of the last item in a pipeline.
set -o pipefail

function main() {
  _ensure_helm_repo
  _install_cert_manager
  _wait_for_pods_ready
  printf '✅ cert-manager installed and ready.\n'
}

function _ensure_helm_repo() {
  if ! helm repo list | grep -q 'jetstack'; then
    printf '➕ Adding jetstack Helm repo...\n'
    helm repo add jetstack https://charts.jetstack.io
  fi
  helm repo update
}

function _install_cert_manager() {
  printf '📦 Installing cert-manager with CRDs...\n'
  helm upgrade --install cert-manager jetstack/cert-manager \
    --namespace cert-manager \
    --create-namespace \
    --set installCRDs=true
}

function _wait_for_pods_ready() {
  printf '⏳ Waiting for cert-manager pods...\n'
  local ready=0 attempts=0 max_attempts=30
  while [[ "${ready}" -eq 0 && "${attempts}" -lt "${max_attempts}" ]]; do
    if kubectl get pods -n cert-manager | grep -q 'Running'; then
      ready=1
    else
      sleep 2
      attempts=$((attempts + 1))
    fi
  done
  [[ "${ready}" -eq 1 ]] || {
    printf '❌ cert-manager pods did not become ready in time.\n' >&2
    exit 1
  }
}

main "$@"
