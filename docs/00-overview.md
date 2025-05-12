# Infrastructure Overview: latencylab.is

This document provides a high-level overview of the infrastructure stack powering `latencylab.is`, with emphasis on operational clarity, modularity, and zero-touch automation wherever possible.

---

## 🌐 DNS

- **Primary Registrar**: [ISNIC](https://www.isnic.is/)
- **DNS Host**: [1984 Hosting FreeDNS](https://www.1984hosting.com/)
- **Manual TXT record support**: required for wildcard certs via `dns-01`
- **Optional NS delegation**: `_acme-challenge.latencylab.is` can be delegated to an API-enabled DNS provider for automation

---

## ☁️ Kubernetes Hosting

- **Provider**: [Infomaniak Public Cloud](https://www.infomaniak.com/en/public-cloud)
- **Platform**: OpenStack-based shared cluster environment
- **Access Method**: Horizon dashboard + OpenStack CLI + downloaded `clouds.yaml`
- **LoadBalancer IPs**: allocated via OpenStack floating IP interface

---

## 📦 Core Services

- **Redirector**: HTTPS 301 from `latencylab.is` to `latencylab.ch` (via Ingress + annotation)
- **Container Registry**: Private Docker registry at `cr.latencylab.is`
- **TLS Automation**: Let's Encrypt via cert-manager using either `http-01` or `dns-01` based on context

---

## 📈 Monitoring as a Service™

A lightweight BATS-based suite runs in headless mode hourly (via cron or CI agent):

- Verifies NS records and FreeDNS health
- Confirms apex + wildcard DNS resolution
- Checks for TLS certificate expiry
- Validates HTTP response codes from all public endpoints

No telemetry or logs are externally shared.

---

## 🧭 Notes

- No stateful data is stored in K8s — all state is config-as-code or external
- Secrets are not committed; they are expected in per-user `~/secrets/latencylab/`
- This document is complemented by service-specific runbooks in the `docs/` folder
