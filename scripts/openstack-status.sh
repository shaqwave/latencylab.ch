#!/usr/bin/env bash
# openstack-status.sh — Inspect OpenStack project state: floating IPs, volumes, cluster metadata

# bash configuration:
# 1) Exit script if you try to use an uninitialized variable.
set -o nounset
# 2) Exit script if a statement returns a non-true return value.
set -o errexit
# 3) Use the error status of the first failure, rather than that of the last item in a pipeline.
set -o pipefail

function main() {
  require::command 'openstack'
  print::floating_ips
  print::volumes
  print::k8s_clusters
}

function require::command() {
  local -r cmd="$1"
  command -v "${cmd}" >/dev/null 2>&1 || {
    printf '❌ Required command not found: %s\n' "${cmd}" >&2
    exit 1
  }
}

function print::floating_ips() {
  printf '\n🌐 Floating IPs:\n'
  openstack floating ip list --format table
}

function print::volumes() {
  printf '\n💾 Block Volumes:\n'
  openstack volume list --format table
}

function print::k8s_clusters() {
  printf '\n☸️  Kubernetes Clusters:\n'
  openstack coe cluster list --format table || printf '(no clusters or missing COE plugin)\n'
}

main "$@"
