#!/usr/bin/env bash
# test_k8s_access.sh
# Diagnoses what a given user/service account can do in a multi-tenant K8s cluster

set -o nounset
set -o errexit
set -o pipefail

echo "🔍 Current Context: $(kubectl config current-context)"
echo "📛 Current Namespace: $(kubectl config view --minify --output 'jsonpath={..namespace}' || echo 'default')"
echo

echo "🔐 Who am I (via token review):"
kubectl auth can-i --list
echo

echo "📦 Listing resources (if allowed):"
for resource in pods configmaps secrets services events; do
  echo "🔸 kubectl get ${resource}:"
  if ! kubectl get "${resource}" 2>/dev/null; then
    echo "  ❌ Access denied or resource not found"
  fi
  echo
done

echo "🔎 RoleBindings and ClusterRoleBindings (if viewable):"
kubectl get rolebindings --all-namespaces 2>/dev/null || echo "❌ Cannot list rolebindings"
kubectl get clusterrolebindings 2>/dev/null || echo "❌ Cannot list clusterrolebindings"

