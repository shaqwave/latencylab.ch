#!/usr/bin/env bash
# get_latencylab_cert.sh
# Obtain or renew a TLS cert covering all latencylab.is domains using certbot with manual DNS mode.

# bash configuration:
# 1) Exit script if you try to use an uninitialized variable.
set -o nounset

# 2) Exit script if a statement returns a non-true return value.
set -o errexit

# 3) Use the error status of the first failure, rather than that of the last item in a pipeline.
set -o pipefail

# Globals
readonly CERT_DIR="$HOME/.ssh/latencylab.is"
readonly CERT_FILE="${CERT_DIR}/tls.pem"
readonly CERTBOT_CONFIG_DIR="${CERT_DIR}/certbot-config"
readonly CERTBOT_WORK_DIR="${CERT_DIR}/certbot-work"
readonly CERTBOT_LOG_DIR="${CERT_DIR}/certbot-logs"
readonly DOMAINS=(latencylab.is www.latencylab.is cr.latencylab.is)

function main() {
  ensure_dirs
  if should_renew || is_rotate_requested "$@"; then
    log_info "Renewing certificate with certbot..."
    certbot certonly \
      --manual \
      --preferred-challenges dns \
      --agree-tos \
      --email 'admin@latencylab.is' \
      ${DOMAINS[@]/#/-d } \
      --config-dir "$CERTBOT_CONFIG_DIR" \
      --work-dir "$CERTBOT_WORK_DIR" \
      --logs-dir "$CERTBOT_LOG_DIR"
    combine_chain
    push_to_k8s
    log_info "TLS cert renewed and saved to ${CERT_FILE}"
  else
    log_info "TLS cert is valid; skipping renewal"
  fi
}

function ensure_dirs() {
  mkdir -p "$CERT_DIR" "$CERTBOT_CONFIG_DIR" "$CERTBOT_WORK_DIR" "$CERTBOT_LOG_DIR"
  chmod 700 "$CERT_DIR"
}

function should_renew() {
  if kubectl get secret -n latencylab-is latencylab-is-tls >/dev/null 2>&1; then
    local crt
    crt=$(kubectl get secret -n latencylab-is latencylab-is-tls -o jsonpath='{.data["tls\.crt"]}' | base64 -d 2>/dev/null || true)
    if [[ -n "$crt" ]]; then
      local expiry
      expiry=$(openssl x509 -enddate -noout <<<"$crt" | cut -d= -f2)
      local expiry_epoch now
      expiry_epoch=$(date -jf "%b %d %T %Y %Z" "$expiry" +%s 2>/dev/null || true)
      now=$(date +%s)
      if [[ -n "$expiry_epoch" && $((expiry_epoch - now)) -ge 2592000 ]]; then
        return 1  # Not time to renew
      fi
    fi
  fi
  return 0  # Secret missing, invalid, or needs renewal
}

function is_rotate_requested() {
  [[ "${1:-}" == "--rotate" ]]
}

function combine_chain() {
  local fullchain="$CERTBOT_CONFIG_DIR/live/${DOMAINS[0]}/fullchain.pem"
  local privkey="$CERTBOT_CONFIG_DIR/live/${DOMAINS[0]}/privkey.pem"
  cat "$fullchain" "$privkey" > "$CERT_FILE"
  chmod 600 "$CERT_FILE"
}

function push_to_k8s() {
  log_info "Updating k8s secrets latencylab-is-tls and cr.latencylab.is.tls"
  local fullchain="$CERTBOT_CONFIG_DIR/live/${DOMAINS[0]}/fullchain.pem"
  local privkey="$CERTBOT_CONFIG_DIR/live/${DOMAINS[0]}/privkey.pem"

  for name in latencylab-is-tls cr.latencylab.is.tls; do
    kubectl -n latencylab-is create secret tls "${name}" \
      --cert="${fullchain}" \
      --key="${privkey}" \
      --dry-run=client -o yaml | kubectl apply -f -
  done
}

function log_info() {
  printf 'ℹ️  INFO: %s\n' "$1"
}

main "$@"
