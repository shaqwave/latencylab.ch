# Tips, Gotchas, and Field Notes

This document collects operational tips, unexpected behaviors, and useful shell patterns observed while maintaining `latencylab.is` infrastructure.

---

## 🧠 DNS + Certs

- `1984` has **no DNS API** → use manual TXT or `_acme-challenge` NS delegation
- Wildcard certs require DNS-01, which requires forward planning
- You can mix apex + `www` A records to same IP for fallback

---

## 🛠 Shell Patterns

- Switch kubeconfig with merge:
  ```bash
  KUBECONFIG=~/.kube/config:/path/to/kubeconfig.yaml kubectl config view --flatten > ~/.kube/config
  ```

- Check TLS expiry for domain:
  ```bash
  echo | openssl s_client -connect latencylab.is:443 -servername latencylab.is 2>/dev/null | openssl x509 -noout -dates
  ```

- Verify TXT record:
  ```bash
  dig TXT _acme-challenge.latencylab.is +short
  ```

---

## 🌐 OpenStack CLI Tips

- Authenticate non-interactively:
  ```bash
  export OS_CLOUD=infomaniak
  openstack server list
  ```

- List floating IPs:
  ```bash
  openstack floating ip list
  ```

- You can pre-assign a floating IP and bind it via K8s annotation

---

## 🧪 BATS Monitoring

- Runs via GitHub Actions or cron container
- Verifies:
    - DNS resolution for apex, `www`, `cr`
    - TLS expiration safety margin
    - HTTP/HTTPS endpoint status codes

---

## 🐾 Gotchas

- Horizon login uses **OpenStack credentials**, not Infomaniak SSO
- LoadBalancer provisioning may hang until Floating IP is bound
- Cert-manager failure is usually due to missing TXT or propagation delay

---

Contributions welcome — log new gotchas or useful one-liners here.
