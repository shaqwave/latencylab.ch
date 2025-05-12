# Infomaniak Public Cloud Setup

This document outlines how to use Infomaniak's OpenStack-based Public Cloud to provision, configure, and maintain Kubernetes infrastructure for `latencylab.is`.

---

## 🛠️ Access Setup

For more detailed instructions on Horizon usage, see [`docs/40-horizon.md`](40-horizon.md).

- Sign into [Infomaniak Manager](https://manager.infomaniak.com/)
- Navigate to **Public Cloud → Project**
- Accept the project invitation if applicable
- Access the OpenStack dashboard (Horizon) from the **API Access** section

### CLI Access

- Download the `openrc.sh` or `clouds.yaml` file from **API Access**
- Prefer `clouds.yaml` + Application Credential for CI/CD
- Use the OpenStack CLI to validate access:

```bash
openstack --os-cloud infomaniak project list
```

---

## 🌐 Network Setup

- Allocate a **Floating IP** via Horizon → Network → Floating IPs
- Save this IP for use in `1984` A records and Ingress
- Attach Floating IP to LoadBalancer service in K8s via annotation or manually

---

## ☸️ Kubernetes Cluster

- Go to **Public Cloud → Kubernetes → New Cluster**
- Choose "Cluster Shared" (1 API server, no SLA) or "Cluster Kubernetes" (dedicated nodes)
- Select region and version (e.g. v1.29+)
- Once provisioned, download the kubeconfig file
- Merge with existing local config if needed:

```bash
KUBECONFIG=~/.kube/config:~/Downloads/kubeconfig.yaml kubectl config view --flatten > ~/.kube/config
```

---

## 🔒 Security Notes

- Do not commit OpenStack credentials
- Use separate Application Credentials for CI roles
- Floating IPs persist unless explicitly deleted
- Avoid running production workloads in the free shared tier

---

## 🧪 Verification Checklist

- [ ] Able to log into Horizon with Application Credential
- [ ] `kubectl get nodes` returns expected hosts
- [ ] Floating IP is reachable and stable
- [ ] DNS points to correct public IP
- [ ] TLS certificates issued successfully

---

## 🧠 Notes

- Kubernetes cluster creation can take ~2–5 minutes
- Horizon UI and OpenStack CLI are tightly coupled — most actions are mirrored
- Autoscaling to 0 is not yet available on the shared plan
- Persistent volume claims consume block storage quota
