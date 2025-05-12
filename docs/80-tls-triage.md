```bash
# 🔧 TLS Certificate Triage Protocol (Manual Secrets Only)

# 1️⃣ List all TLS secrets and check they exist
kubectl get secret -A | grep tls

# Inspect a specific TLS secret
kubectl get secret <secret-name> -n latencylab-is -o yaml

# 2️⃣ Check the secret is of correct type and not empty
# Should show: type: kubernetes.io/tls
# Fields: data.tls.crt and data.tls.key should be non-empty

# 3️⃣ Check Ingress TLS reference
kubectl get ingress -n latencylab-is -o yaml | grep -A 5 tls:
kubectl get ingress <ingress-name> -n latencylab-is -o yaml

# Verify:
# - .spec.tls[].hosts matches DNS entries
# - .spec.tls[].secretName matches your TLS secret

# 4️⃣ Confirm DNS points to Ingress controller
nslookup <your-hostname>
dig +short <your-hostname>
kubectl get svc -A | grep LoadBalancer

# 5️⃣ Check Ingress annotations and class
kubectl get ingress <ingress-name> -n latencylab-is -o yaml | grep annotations -A 10

# Look for:
# - kubernetes.io/ingress.class or ingressClassName
# - nginx-specific config if using nginx ingress

# 6️⃣ Examine events for TLS or Ingress failures
kubectl describe ingress <ingress-name> -n latencylab-is
kubectl get events -n latencylab-is --sort-by=.metadata.creationTimestamp

# 7️⃣ Test TLS handshake directly
# Replace <load-balancer-ip> and <host> as needed
curl -v https://<your-host> --resolve <your-host>:443:<load-balancer-ip>

# 8️⃣ Inspect TLS certificate expiration and subject
kubectl get secret <secret-name> -n latencylab-is -o jsonpath='{.data.tls\.crt}' \
  | base64 -D | openssl x509 -text -noout

# Look for:
# - Not Before / Not After dates
# - CN / SAN fields
# - Issuer / Subject

# ✅ Summary Fixes
# - Secret not found? Create a new kubernetes.io/tls secret.
# - Secret empty or wrong type? Recreate it with correct cert/key.
# - Ingress pointing to wrong secret? Update .spec.tls[].secretName.
# - DNS incorrect? Update A/AAAA records.
# - TLS expired? Reissue and replace the cert in the secret.

# 🔁 After fix: re-check Ingress and curl TLS handshake
```