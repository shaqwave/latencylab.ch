# Kubernetes Runbook: latencylab.is

This document outlines common operational tasks, expected cluster layout, and standard deployment patterns for the `latencylab.is` Kubernetes environment.

---

## ☸️ Cluster Expectations

- Single-region deployment (Infomaniak Public Cloud, shared control plane)
- Helm 3 used for all deploys
- Public workloads routed via Ingress
- External DNS and TLS managed out-of-band (manual or cert-manager)
- No persistent state within K8s except registry storage

---

## 🧪 Cluster Verification

```bash
kubectl get nodes
kubectl get pods --all-namespaces
kubectl get ingress
```

Check that:
- All pods are `Running`
- External IP is assigned via LoadBalancer
- `cr.latencylab.is` and apex domain resolve and respond

```bash
kubectl get --raw /healthz
kubectl get namespace
```

---

## 🚀 Deploy Workflow

1. Update Helm chart values as needed
2. Package and deploy:

```bash
helm upgrade --install latencylab-core ./helm-charts/latencylab-core \
  -f ./helm-charts/latencylab-core/values.yaml \
  -n latencylab-is
```

3. Verify TLS and redirect behavior

---

## 🔐 Kubeconfig Management

- Initial `kubeconfig` downloaded from Infomaniak web console
- Canonical local config: `~/.kube/config`
- Script: `./scripts/setup/merge_kubeconfig.sh` performs:
    - Merge with backup
    - Cluster name: `pck-nhl6mx4` → `latencylab-is`
    - Context name: `kubernetes-admin@pck-nhl6mx4` → `latencylab-is`

To verify:
```bash
kubectl config use-context latencylab-is
kubectl config get-contexts
```

To test API access:
```bash
./scripts/test_kube_cert.sh
```

---

## 🧼 Namespace Definition

Namespace is managed declaratively:

```yaml
# k8s/namespaces/latencylab-is.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: latencylab-is
```

Apply:
```bash
kubectl apply -f k8s/namespaces/latencylab-is.yaml
```

---

## 🔁 Cert Renewal (if DNS-01)

- Manually add TXT record to 1984 FreeDNS
- Or configure `_acme-challenge.latencylab.is` as a delegated zone
- cert-manager will retry on failures automatically

---

## 🧪 BATS Tests

Test suites run in CI (`.github/workflows/`) or manually:

- `test/bats/dns.bats`: A record + TXT validation
- `test/bats/tls.bats`: Cert validity + Let's Encrypt CA check

Use `FD3` for debug visibility. `gtimeout` required on macOS:
```bash
brew install coreutils
```

---

## 🧼 Maintenance

- Safe restart:
```bash
kubectl rollout restart deployment/<name>
```

- PVC status:
```bash
kubectl get pvc
```

- TLS cert expiry and issuer checked via BATS + CI

---

## 🧠 Notes

- No CRDs other than cert-manager
- Cluster config is YAML + Helm only — no Terraform/Pulumi
- Secrets are mounted from CI or pulled from secure local paths
- `kubectl config set-cluster --certificate-authority-data` is **invalid**; use `yq` instead
- K8s API errors like `Unauthorized` often indicate broken cert chain or context mismatch
