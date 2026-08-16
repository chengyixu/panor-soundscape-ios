#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
snapshot="docs/contracts/soundscape-openapi.json"
jq -e '.info.title == "Soundscape API" and (.paths | type == "object")' "$snapshot" >/dev/null
printf 'PASS Soundscape OpenAPI snapshot is valid\n'

if [[ "${SOUNDSCAPE_VERIFY_LIVE:-0}" == "1" ]]; then
  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' EXIT
  curl --retry 3 --retry-all-errors --connect-timeout 10 --max-time 30 -fsS \
    https://www.panor.tech/soundscape/api/openapi.json | jq -S . > "$tmp_dir/openapi.json"
  jq -S . "$snapshot" | diff -u - "$tmp_dir/openapi.json"
  printf 'PASS live Soundscape OpenAPI matches pinned snapshot\n'

  auth_status="$(curl --retry 3 --retry-all-errors --connect-timeout 10 --max-time 30 -sS \
    -o "$tmp_dir/auth-validation.json" -w '%{http_code}' \
    -X POST https://www.panor.tech/api/auth/register \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
    --data '{}')"
  [[ "$auth_status" == "400" ]]
  jq -e '.success == false and (.message | test("Email and password"))' "$tmp_dir/auth-validation.json" >/dev/null
  printf 'PASS live unified auth requires email and password for registration\n'

  curl --retry 3 --retry-all-errors --connect-timeout 10 --max-time 30 -fsS \
    https://www.panor.tech/api/auth/config > "$tmp_dir/auth-config.json"
  expected_server_client_id="$(plutil -extract GIDServerClientID raw Resources/Info.plist)"
  [[ "$(jq -r '.googleClientId' "$tmp_dir/auth-config.json")" == "$expected_server_client_id" ]]
  printf 'PASS live Google audience matches the native app configuration\n'

  apple_status="$(curl --retry 3 --retry-all-errors --connect-timeout 10 --max-time 30 -sS \
    -o "$tmp_dir/apple-validation.json" -w '%{http_code}' \
    -X POST https://www.panor.tech/api/auth/apple \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
    --data '{}')"
  [[ "$apple_status" == "400" ]]
  jq -e '.success == false and (.message | test("Apple authorization"))' "$tmp_dir/apple-validation.json" >/dev/null
  printf 'PASS live native Apple auth route is registered\n'

  curl --retry 3 --retry-all-errors --connect-timeout 10 --max-time 30 -fsS \
    https://www.panor.tech/api/auth/me \
    -H 'Authorization: Bearer invalid-contract-probe' > "$tmp_dir/auth-me.json"
  jq -e '.success == true and .user == null' "$tmp_dir/auth-me.json" >/dev/null
  printf 'PASS live unified auth accepts Bearer session lookup\n'
fi
