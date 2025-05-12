#!/usr/bin/env bats

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

@test "All domains redirect to https://latencylab.ch" {
  expected="https://latencylab.ch"
  expected_base="${expected%/}"
  failures=0

  domains=(
    latencylab.ch latencylab.co latencylab.net latencylab.org latencylab.is
    shaqwave.ch shaqwave.co shaqwave.com shaqwave.dev shaqwave.net shaqwave.org shaqwave.tech
  )

  for domain in "${domains[@]}"; do
    for prefix in "" www.; do
      for protocol in https http; do
        fqdn="${prefix}${domain}"
        url="${protocol}://${fqdn}"

        # ✏️ Replace: run curl ...
        run curl -Ls --max-time 10 --connect-timeout 5 --fail -o /dev/null -w "%{http_code}|%{url_effective}" "$url"

        # ✅ Added: Shadow curl output and status immediately
        curl_status="${status}"
        curl_out="${output}"

        if [[ "$curl_status" -ne 0 ]]; then
          printf '  ❌ curl failed for %s status=%d\n' "$url" "$curl_status">&3
          # ✅ Added: Show raw curl output
          printf '    ⚠️ curl output: %s\n' "$curl_out" >&3

          # Attempt single redirect trace
          redirect_url="$(curl -sL --max-time 5 --connect-timeout 2 -o /dev/null -D - "$url" | awk '/^HTTP\/.* 30[1-9]/ { show=1; next } /^HTTP\/.* 200/ { show=0 } show && /^Location:/ { print $2; exit }' | tr -d '\r')"
          if [[ -n "$redirect_url" ]]; then
            printf '    ↪ 301 Location: %s\n' "$redirect_url" >&3
          fi

          printf '    ↳ NS records for %s:\n' "$domain" >&3
          ns="$(dig +short NS "$domain")"
          if [[ -z "$ns" ]]; then
            ns="$(dig +short NS "$domain" @1.1.1.1)"
            if [[ -z "$ns" ]]; then
              ns="$(dig +short NS "$domain" @8.8.8.8)"
            fi
          fi
          indent="      "
          if [[ -z "$ns" ]]; then
            printf '%s<none>\n' "$indent" >&3
            ((failures++))
            continue
          fi
          while read -r line; do
            printf '%s%s\n' "$indent" "$line" >&3
          done <<< "$ns"

          printf '      🔍 A record for %s:\n' "$fqdn" >&3
          a="$(dig +short A "$fqdn")"
          if [[ -z "$a" ]]; then
            a="$(dig +short A "$fqdn" @1.1.1.1)"
            if [[ -z "$a" ]]; then
              a="$(dig +short A "$fqdn" @8.8.8.8)"
            fi
          fi
          indent="        "
          if [[ -z "$a" ]]; then
            printf '%s<none>\n' "$indent" >&3
            printf '        🔍 CNAME for %s:\n' "$fqdn" >&3
            cname="$(dig +short CNAME "$fqdn")"
            if [[ -z "$cname" ]]; then
              cname="$(dig +short CNAME "$fqdn" @1.1.1.1)"
              if [[ -z "$cname" ]]; then
                cname="$(dig +short CNAME "$fqdn" @8.8.8.8)"
              fi
            fi
            indent="          "
            if [[ -z "$cname" ]]; then
              printf '%s<none>\n' "$indent" >&3
            else
              while read -r line; do
                printf '%s%s\n' "$indent" "$line" >&3
              done <<< "$cname"
            fi
          else
            while read -r line; do
              printf '%s%s\n' "$indent" "$line" >&3
            done <<< "$a"
          fi

          ((failures++))
          continue
        fi

        # 🛠 Modified: Use curl_out instead of output
        http_code="${curl_out%%|*}"
        final_url="${curl_out#*|}"
        normalized="${final_url%/}"

        if [[ "$normalized" != "$expected_base" ]]; then
          printf '  ❌ %s redirected to unexpected location:\n' "$url" >&3
          printf '    → %s (HTTP %s)\n' "$final_url" "$http_code" >&3
          ((failures++))
        else
          printf '  ✅ %s → %s (HTTP %s)\n' "$url" "$final_url" "$http_code" >&3
        fi
      done
    done
  done

  printf '\n' >&3
  if [[ "$failures" -ne 0 ]]; then
    printf '🛑 Total redirect failures: %s\n' "$failures" >&3
    false
  else
    printf '🎉 All domains successfully redirect to %s\n' "$expected" >&3
  fi
}
