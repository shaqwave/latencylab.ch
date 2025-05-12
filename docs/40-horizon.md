# Horizon Dashboard (OpenStack UI)

This document explains how to access and navigate the Horizon dashboard provided by Infomaniak’s Public Cloud, and how to use it for managing networking, floating IPs, and Kubernetes resources.

---

## 🔐 Logging In

- URL: [https://horizon.pub1.infomaniak.cloud](https://horizon.pub1.infomaniak.cloud)
- Credentials:
    - **Username**: from `clouds.yaml` or `openrc.sh`
    - **Password**: generated via API Access → Create Password
    - **Domain**: `Default`
    - **Project**: your assigned project name

🚫 Do not attempt to log in using your `manager.infomaniak.com` SSO credentials — Horizon uses separate OpenStack authentication.

---

## 🧭 Key Areas

| Section         | Purpose                                    |
|----------------|---------------------------------------------|
| **Compute**     | Manage instances (VMs), key pairs           |
| **Network**     | Create and manage floating IPs, subnets     |
| **Volumes**     | Create/attach persistent block storage      |
| **Orchestration** | View stacks (not used here)              |
| **API Access**  | Download RC/YAML files, manage credentials  |

---

## 🌐 Managing Floating IPs

1. Go to **Network → Floating IPs**
2. Click **Allocate IP to Project**
3. Optionally specify a DNS name/domain (leave blank for stealth)
4. Associate with a Kubernetes LoadBalancer or leave unattached for now

---

## 📦 Managing Kubernetes

- Horizon provides limited K8s interaction — use `kubectl` and Helm for workload management
- You can allocate/track floating IPs here, but apply manifests via CI or CLI
- Review security group rules if ingress fails unexpectedly

---

## 🧪 Verification Checklist

- [ ] Horizon login works with generated OpenStack password
- [ ] Floating IPs can be allocated and associated
- [ ] `kubectl` context from downloaded kubeconfig works

---

## 🔐 Notes

- Use Application Credentials for non-interactive CI/CD
- Horizon exposes all OpenStack resources via GUI — changes here affect the live cluster
- Access logs and API calls are available via Horizon for audit purposes
