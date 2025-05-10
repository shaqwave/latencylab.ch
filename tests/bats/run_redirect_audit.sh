#!/usr/bin/env bash
# run_redirect_audit.sh
# Launches redirect_audit.bats using correct GITROOT and BATS_LIB_PATH setup

# bash configuration:
# 1) Exit script if you try to use an uninitialized variable.
set -o nounset

# 2) Exit script if a statement returns a non-true return value.
set -o errexit

# 3) Use the error status of the first failure, rather than that of the last item in a pipeline.
set -o pipefail

function main() {
  local -r gitroot="$(git rev-parse --show-toplevel)"
  local -r bats_test="${gitroot}/tests/bats/redirect_audit.bats"
  local -r bats_lib="${gitroot}/tests/bats/test_helper"

  if [[ ! -f "${bats_test}" ]]; then
    echo "❌ BATS test file not found: ${bats_test}"
    exit 1
  fi

  if [[ ! -d "${bats_lib}" ]]; then
    echo "❌ BATS library path not found: ${bats_lib}"
    echo "👉 Expected bats-support/ and bats-assert/ under:"
    echo "   ${bats_lib}"
    exit 1
  fi

  echo "🧪 Running: ${bats_test}"
  echo "📚 BATS_LIB_PATH: ${bats_lib}"
  echo

  BATS_LIB_PATH="${bats_lib}" bats "${bats_test}"
}

main "$@"
