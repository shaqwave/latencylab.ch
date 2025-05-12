# 1984 FreeDNS Setup for latencylab.is

This runbook describes how to configure authoritative DNS for `latencylab.is` using 1984 Hosting's FreeDNS service.

---

## 🔐 Account Access

- Provider: [1984 Hosting](https://1984.hosting/)
- DNS interface: https://1984.hosting/controlpanel/
- Credentials: stored in `~/secrets/latencylab/1984-hosting.json`

---

## 🌐 Nameservers

Once delegated from ISNIC (see `10-isnic.md`), 1984’s nameservers should be:

- `ns0.1984.is`
- `ns1.1984.is`
- `ns2.1984hosting.com`

---

## 🛠️ Creating a Zone

1. Log in to the 1984 Hosting control panel
2. Go to **DNS Zones**
3. Click **Add Domain** → enter `latencylab.is`
4. Ensure it is marked **active**

---

## 📄 Essential Records

| Type | Name                  | Value                        |
|------|-----------------------|------------------------------|
| A    | `latencylab.is`       | Floating IP of K8s ingress   |
| A    | `www.latencylab.is`   | Same as apex or CNAME        |
| A    | `cr.latencylab.is`    | Same IP or dedicated IP      |
| TXT  | `_acme-challenge.*`   | Let’s Encrypt DNS challenge  |

Wildcards (`*.latencylab.is`) are optional unless using wildcard certs.

---

## 🔄 Manual TXT Record Insertion

If using `dns-01` challenge via cert-manager or `acme.sh`:

1. Add TXT records manually when prompted
2. Propagation takes ~1–3 minutes
3. TTL defaults to 3600s unless overridden

---

## 🧪 Verification Checklist

- [ ] Zone is created and marked active
- [ ] NS entries match ISNIC delegation
- [ ] A and TXT records propagate via `dig`
- [ ] Monitoring confirms resolution for apex, www, and registry

---

## 🔐 Notes

- 1984 does **not** provide an API
- Manual intervention is required for cert renewals unless `_acme-challenge` is delegated
- Zone export/backup must be done via web UI copy/export
