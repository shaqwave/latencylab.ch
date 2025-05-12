# ISNIC Domain Management: latencylab.is

This runbook documents how to manage the `.is` domain registration and DNS delegation through [ISNIC](https://www.isnic.is/).

---

## 🔐 Account Access

- Domain registrar: ISNIC
- Login portal: https://www.isnic.is/en/login
- Admin contact and billing email: [REDACTED — store locally in secrets folder]

---

## 📄 Domain Details

- Primary domain: `latencylab.is`
- Registration status: active, auto-renewed annually
- Name server delegation: handled via the ISNIC UI with provider presets

---

## 🔧 Updating Name Servers

1. Log into https://www.isnic.is/en/login
2. Navigate to "Domains" → `latencylab.is`
3. Click "Modify"
4. Use the “Choose ISP:” dropdown (labeled in English)
5. Select `1984 ehf` from the list — this is the Icelandic-registered entity for 1984 Hosting
6. ISNIC will automatically populate the correct NS records
7. Save and verify propagation

📝 Changes take effect after TTL expiry and ISNIC-side verification.

---

## 🧪 Verification Checklist

- [ ] Provider selected as `1984 ehf`
- [ ] NS records auto-populated correctly by ISNIC
- [ ] Delegated NSs match FreeDNS resolution
- [ ] BATS monitoring confirms DNS resolution

---

## 💡 Notes

- ISNIC supports provider-assisted delegation via dropdown (entries in Icelandic)
- No public API; all changes must be manual
- Email notifications are sent for every change — archive them locally
- Registrar auth code and login credentials must be stored securely
