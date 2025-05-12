#!/usr/bin/env bash
# deploy.sh
# Deploy or upgrade the latencylab-core Helm chart to the latencylab-is namespace.

# bash configuration:
# 1) Exit script if you try to use an uninitialized variable.
set -o nounset
# 2) Exit script if a statement returns a non-true return value.
set -o errexit
# 3) Use the error status of the first failure, rather than that of the last item in a pipeline.
set -o pipefail

readonly CHART_NAME='latencylab-core'
readonly NAMESPACE='latencylab-is'
readonly VALUES_FILE='./helm-charts/latencylab-core/values.yaml'
readonly CHART_PATH='./helm-charts/latencylab-core'
readonly KUBECONFIG_PATH="${KUBECONFIG:-$HOME/.kube/config}"
readonly LOG_FILE="./.results/helm-deploy.$(date +%s).log"

function main() {
  local -r commit_flag="${1:-}"

  _ensure_helm_available
  _ensure_kubeconfig_valid
  # _maybe_install_crds "${commit_flag}"
  _run_deploy "${commit_flag}"
}

function _ensure_helm_available() {
  command -v helm >/dev/null || {
    printf '❌ Helm not found in PATH. Aborting.\n' >&2
    exit 1
  }
}

function _ensure_kubeconfig_valid() {
  [[ -f "${KUBECONFIG_PATH}" ]] || {
    printf '❌ kubeconfig not found at: %s\n' "${KUBECONFIG_PATH}" >&2
    exit 1
  }
}

function _maybe_install_crds() {
  if [[ "$1" == "--commit" ]]; then
    printf '📦 Installing cert-manager CRDs...\n'
    kubectl apply --validate=false -f \
      https://github.com/cert-manager/cert-manager/releases/download/v1.17.2/cert-manager.crds.yaml \
      || {
        printf '❌ Failed to install CRDs\n' >&2
        exit 1
      }
  fi
}

function _run_deploy() {
  local -r commit_flag="$1"
  local -a helm_args=(
    upgrade --install "${CHART_NAME}" "${CHART_PATH}"
    -f "${VALUES_FILE}"
    --namespace "${NAMESPACE}"
    --create-namespace
    --kubeconfig "${KUBECONFIG_PATH}"
    --debug
  )

  if [[ "${commit_flag}" != "--commit" ]]; then
    helm_args+=(--dry-run)
    printf '🧪 Performing dry run of Helm deploy...\n'
  else
    printf '🚀 Committing Helm deploy...\n'
  fi

  helm "${helm_args[@]}" | tee "${LOG_FILE}"
}

main "$@"
