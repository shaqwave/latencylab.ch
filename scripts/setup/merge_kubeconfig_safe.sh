#!/usr/bin/env bash
# merge_kubeconfig_safe.sh
# Safely merge kubeconfigs using JSON and jq, rename cluster/context to 'latencylab-is', output to ~/.kube/config

# bash configuration:
# 1) Exit script if you try to use an uninitialized variable.
set -o nounset
# 2) Exit script if a statement returns a non-true return value.
set -o errexit
# 3) Use the error status of the first failure, rather than that of the last item in a pipeline.
set -o pipefail

readonly SRC_KUBECONFIG="${HOME}/.kube/latencylab/config"
readonly DEST_KUBECONFIG="${HOME}/.kube/config"
readonly TMP_JSON="$(mktemp)"
readonly TMP_PATCHED="$(mktemp)"
readonly TMP_FINAL="$(mktemp)"
readonly CONTEXT_NAME='latencylab-is'
readonly CLUSTER_NAME='latencylab-is'

function main() {
  local -r commit_flag="${1:-}"
  _assert_source_exists
  _merge_kubeconfigs_to_json
  _apply_rename_patch
  _convert_back_to_yaml
  _preview_and_commit "${commit_flag}"
}

function _assert_source_exists() {
  [[ -f "${SRC_KUBECONFIG}" ]] || {
    printf '❌ Source kubeconfig not found: %s\n' "${SRC_KUBECONFIG}" >&2
    exit 1
  }
}

function _merge_kubeconfigs_to_json() {
  KUBECONFIG="${SRC_KUBECONFIG}:${DEST_KUBECONFIG}" \
    kubectl config view --flatten --output=json > "${TMP_JSON}"
}

function _apply_rename_patch() {
  jq "$(jq_expr_patch)" "${TMP_JSON}" > "${TMP_PATCHED}"
}

function _convert_back_to_yaml() {
  yq eval --prettyPrint "${TMP_PATCHED}" > "${TMP_FINAL}"
}

function _preview_and_commit() {
  local -r commit_flag="$1"
  printf '\n🔍 Preview of merged changes (unified diff):\n'
  diff -u "${DEST_KUBECONFIG}" "${TMP_FINAL}" || true

  if [[ "${commit_flag}" != "--commit" ]]; then
    printf '\n🛑 Dry run only. Run again with --commit to apply changes.\n'
    exit 0
  fi

  cp -v "${DEST_KUBECONFIG}" "${DEST_KUBECONFIG}.bak.$(date +%s)"
  mv -v "${TMP_FINAL}" "${DEST_KUBECONFIG}"
  printf '✅ Merge complete. Current context: %s\n' "${CONTEXT_NAME}"
}

function jq_expr_patch() {
  cat <<'JQ_RENAME'
{
  apiVersion: .apiVersion,
  kind: .kind,
  preferences: .preferences,
  "current-context": "latencylab-is",
  clusters: (
    .clusters | map(
      if .name == "pck-nhl6mx4" then
        .name = "latencylab-is"
      else . end
    )
  ),
  contexts: (
    .contexts | map(
      if .name == "kubernetes-admin@pck-nhl6mx4" then
        .name = "latencylab-is" |
        .context.cluster = "latencylab-is"
      else . end
    )
  ),
  users: .users
}
JQ_RENAME
}

main "$@"
