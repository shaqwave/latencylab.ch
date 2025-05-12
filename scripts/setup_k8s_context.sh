#!/usr/bin/env bash
# setup_k8s_context.sh
# Loads OpenStack creds and configures KUBECONFIG for latencylab-is

# bash configuration:
# 1) Exit script if you try to use an uninitialized variable.
set -o nounset

# 2) Exit script if a statement returns a non-true return value.
set -o errexit

# 3) Use the error status of the first failure, rather than that of the last item in a pipeline.
set -o pipefail

readonly OPENRC="${HOME}/.openstack/openrc.txt"
readonly CLUSTER_NAME="latencylab-is"
readonly KCFG_DIR="${HOME}/.kube/latencylab"

function main() {
  if ! grep -q '^export OS_PASSWORD=' "${OPENRC}"; then
    read -rsp "🔐 Enter OpenStack password: " OS_PASSWORD
    export OS_PASSWORD
    echo
  fi

  echo '🔐 Sourcing OpenStack credentials...'
  source "${OPENRC}"

  echo '📡 Verifying OpenStack authentication...'
  openstack token issue >/dev/null || {
    echo '❌ OpenStack authentication failed.' >&2
    exit 1
  }

  echo "🔧 Fetching kubeconfig for cluster: ${CLUSTER_NAME}"
  mkdir -p "${KCFG_DIR}"
  openstack coe cluster config "${CLUSTER_NAME}" --dir "${KCFG_DIR}" --force

  echo "🌐 Switching KUBECONFIG to: ${KCFG_DIR}/config"
  export KUBECONFIG="${KCFG_DIR}/config"

  echo '✅ Verifying Kubernetes access...'
  kubectl config use-context "${CLUSTER_NAME}" 2>/dev/null || true
  kubectl get nodes
}

main
