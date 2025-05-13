#!/usr/bin/env bash
# scaffold_latencylab.sh
# Create initial directory and file structure for latencylab.is infrastructure repo

set -euo pipefail

PROJECT_ROOT="latencylab.is"

mkdir -p "${PROJECT_ROOT}"/{docs,terraform,helm-charts/latencylab-core,helm-charts/latencylab-core/templates,k8s/base,k8s/overlays/infomaniak,scripts,.github/workflows}

# Top-level files
touch "${PROJECT_ROOT}/README.md"
touch "${PROJECT_ROOT}/.gitignore"

# Documentation files
touch "${PROJECT_ROOT}"/docs/{00-overview.md,10-isnic.md,20-1984-freedns.md,30-infomaniak.md,40-horizon.md,50-k8s-runbook.md,99-tips.md}

# Helm chart
touch "${PROJECT_ROOT}/helm-charts/latencylab-core/Chart.yaml"
touch "${PROJECT_ROOT}/helm-charts/latencylab-core/values.yaml"
touch "${PROJECT_ROOT}/helm-charts/latencylab-core/templates/clusterissuer.yaml"
touch "${PROJECT_ROOT}/helm-charts/latencylab-core/templates/redirect-ingress.yaml"
touch "${PROJECT_ROOT}/helm-charts/latencylab-core/templates/registry-deployment.yaml"
touch "${PROJECT_ROOT}/helm-charts/latencylab-core/templates/registry-service.yaml"
touch "${PROJECT_ROOT}/helm-charts/latencylab-core/templates/registry-ingress.yaml"
touch "${PROJECT_ROOT}/helm-charts/latencylab-core/templates/pvc.yaml"

# K8s overlays/base
touch "${PROJECT_ROOT}/k8s/base/README.md"
touch "${PROJECT_ROOT}/k8s/overlays/infomaniak/kustomization.yaml"

# Scripts
touch "${PROJECT_ROOT}/scripts/deploy.sh"
touch "${PROJECT_ROOT}/scripts/openstack-status.sh"
touch "${PROJECT_ROOT}/scripts/dns-delegate-acme.sh"

# GitHub workflows
touch "${PROJECT_ROOT}/.github/workflows/publish.yaml"

# Add .keep files for empty directories
for dir in \
  "${PROJECT_ROOT}/terraform" \
  "${PROJECT_ROOT}/helm-charts/latencylab-core/templates" \
  "${PROJECT_ROOT}/k8s/base" \
  "${PROJECT_ROOT}/k8s/overlays/infomaniak" \
  "${PROJECT_ROOT}/scripts" \
  "${PROJECT_ROOT}/.github/workflows"
do
  touch "${dir}/.keep"
done

printf "✅ Scaffolding created under ./%s\n" "${PROJECT_ROOT}"

