# latencylab.is

This repository contains the complete configuration and automation for operating the infrastructure behind the `latencylab.is` domain. It manages:

- DNS (1984 FreeDNS + delegation)
- Domain registration (ISNIC)
- Kubernetes-based deployments (Infomaniak Public Cloud)
- Helm-based deployment for:
  - 301 redirector from `latencylab.is` to `latencylab.ch`
  - A self-hosted container registry at `cr.latencylab.is`
  - Let's Encrypt TLS automation using cert-manager

> This repository **excludes secrets**, cloud credentials, or private key material. Those are managed out-of-band.

---

## 🔧 Stack Overview

- **Cluster Provider**: Infomaniak Public Cloud (OpenStack)
- **DNS Provider**: 1984 Hosting FreeDNS (primary), with optional `_acme-challenge` delegation
- **Certificates**: Let's Encrypt via cert-manager (DNS-01 or HTTP-01)
- **Chart Manager**: Helm 3
- **GitHub Pages**: Used as a Helm chart registry
- **Monitoring**: Cloud-based BATS tests to verify DNS, NS, TLS cert expiry, and endpoint availability

---

## 📦 Helm Packages

This repo publishes a Helm chart `latencylab-core` for deploying:

- TLS automation (cert-manager + issuer)
- Ingress + redirector
- Container registry service

---

## 📂 Repo Structure

```text
latencylab.is/
├── README.md
├── docs/              # Runbooks and external service configs
├── helm-charts/       # Core latencylab Helm charts
├── k8s/               # Base YAML and overlays
├── scripts/           # Operational shell tools
├── terraform/         # (Intentionally unused)
├── .github/workflows/ # CI for Helm publish, lint, etc.
```

---

## 🚫 Philosophy

- ❌ No Terraform
- ❌ No Pulumi
- ✅ All infra and workloads must be reviewable as YAML or shell
- ✅ Scripts must be safe for use by junior operators (no footguns)

---

## 🧠 Quickstart

```bash
# 1. Install Helm and kubectl
# 2. Ensure OpenStack CLI access or Kube context

cd latencylab.is
./scripts/deploy.sh
```

---

## 🔐 Secrets

All secrets (e.g., `clouds.yaml`, OpenStack credentials, registry auth) must be stored in `~/secrets/latencylab/` or equivalent per-machine paths and are never checked into Git.
