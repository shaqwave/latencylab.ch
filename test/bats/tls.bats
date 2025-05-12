#!/usr/bin/env bats

load '../test_helper.sh'

setup() {
  HOSTS=(
    latencylab.is
    www.latencylab.is
    cr.latencylab.is
  )

  if ! command -v gtimeout >/dev/null; then
    echo "❌ gtimeout not found. Please install with: brew install coreutils" >&3
    exit 1
  fi

  check_cert() {
    echo | openssl s_client -connect "$1:443" -servername "$1" 2>/dev/null | \
      openssl x509 -noout -checkend 86400
  }

  check_issuer() {
    echo | openssl s_client -connect "$1:443" -servername "$1" 2>/dev/null | \
      openssl x509 -noout -issuer
  }

  export -f check_cert
  export -f check_issuer
}

@test "TLS: All public endpoints present valid, non-expired certs" {
  failures=()
  for host in "${HOSTS[@]}"; do
    run gtimeout 1s bash -c "check_cert \"$host\""
    if [[ "$status" -eq 124 ]]; then
      failures+=("$host: TLS check timed out")
    elif [[ "$status" -ne 0 ]]; then
      failures+=("$host: expired or missing cert")
    fi
  done

  if (( ${#failures[@]} > 0 )); then
    for msg in "${failures[@]}"; do
      printf '❌ %s\n' "$msg" >&3
    done
    false
  fi
}

@test "TLS: All certs are issued by Let's Encrypt" {
  failures=()
  for host in "${HOSTS[@]}"; do
    run gtimeout 1s bash -c "check_issuer \"$host\""
    captured_output="$output"
    if [[ "$status" -eq 124 ]]; then
      failures+=("$host: TLS issuer check timed out")
    elif [[ "$status" -ne 0 ]]; then
      failures+=("$host: could not retrieve issuer")
    elif ! echo "$captured_output" | grep -q "Let's Encrypt"; then
      failures+=("$host: unexpected issuer: $captured_output")
    fi
  done

  if (( ${#failures[@]} > 0 )); then
    for msg in "${failures[@]}"; do
      printf '❌ %s\n' "$msg" >&3
    done
    false
  fi
}
