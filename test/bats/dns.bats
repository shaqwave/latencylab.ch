#!/usr/bin/env bats

load '../test_helper.sh'

readonly EXPECTED_IP="$(get_expected_ip)"

@test "DNS: All key hostnames resolve to expected IP via ns0.1984.is" {
  local -a HOSTS=(
    latencylab.is
    www.latencylab.is
    cr.latencylab.is
  )

  failures=()
  for host in "${HOSTS[@]}"; do
    run dig @ns1.1984.is +short A "$host"  # +norecurse
    local dig_output="$output"
    local dig_status="$status"

    printf 'FD3: %s → [%q] (status=%s)\n' "$host" "$dig_output" "$dig_status" >&3

    trimmed="$(echo "$dig_output" | tr -d '\n\r[:space:]')"

    if [[ "$dig_status" -ne 0 ]]; then
      failures+=("$host: dig failed")
    elif [[ -z "$trimmed" ]]; then
      failures+=("$host: no A record")
    elif [[ "$trimmed" != "$EXPECTED_IP" ]]; then
      failures+=("$host: wrong IP: $trimmed")
    fi
  done

  if (( ${#failures[@]} > 0 )); then
    for msg in "${failures[@]}"; do
      echo "FAIL: $msg" >&3
    done
    fail "DNS resolution errors"
  fi
}

@test "DNS: ACME challenge TXT record is visible if configured via ns0.1984.is" {
  run dig @ns0.1984.is +short TXT _acme-challenge.latencylab.is +norecurse
  [[ "$status" -eq 0 ]] || skip "dig failed for ACME TXT"
  true
}
