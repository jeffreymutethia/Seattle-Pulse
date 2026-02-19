#!/usr/bin/env bash
set -euo pipefail

BACKEND_BASE_URL="${BACKEND_BASE_URL:-http://localhost:5050}"
FRONTEND_BASE_URL="${FRONTEND_BASE_URL:-http://localhost:3000}"

DEMO_EMAIL="${DEMO_EMAIL:-demo@seattlepulse.local}"
DEMO_PASSWORD="${DEMO_PASSWORD:-DemoPass123!}"

TMP_DIR="$(mktemp -d)"
COOKIE_JAR="$TMP_DIR/cookies.txt"
trap 'rm -rf "$TMP_DIR"' EXIT

request() {
  local method="$1"
  local url="$2"
  local data="${3:-}"
  local body_file="$TMP_DIR/body.txt"
  local code

  if [[ -n "$data" ]]; then
    code="$(curl -sS -o "$body_file" -w "%{http_code}" \
      -X "$method" \
      -H "Content-Type: application/json" \
      -c "$COOKIE_JAR" -b "$COOKIE_JAR" \
      --data "$data" \
      "$url")"
  else
    code="$(curl -sS -o "$body_file" -w "%{http_code}" \
      -X "$method" \
      -c "$COOKIE_JAR" -b "$COOKIE_JAR" \
      "$url")"
  fi

  echo "$code"
  cat "$body_file"
}

echo "==> Backend health check"
health_output="$(request GET "$BACKEND_BASE_URL/healthz")"
health_code="$(echo "$health_output" | head -n1)"
health_body="$(echo "$health_output" | tail -n +2)"
if [[ "$health_code" != "200" ]]; then
  echo "FAIL: /healthz returned $health_code"
  exit 1
fi
echo "PASS: /healthz returned 200"
echo "$health_body"

echo "==> Guest feed check"
feed_output="$(request GET "$BACKEND_BASE_URL/api/v1/content/guest_feed?page=1&per_page=2")"
feed_code="$(echo "$feed_output" | head -n1)"
feed_body="$(echo "$feed_output" | tail -n +2)"
if [[ "$feed_code" != "200" ]]; then
  echo "FAIL: guest_feed returned $feed_code"
  exit 1
fi
if ! echo "$feed_body" | grep -Eq '"success"[[:space:]]*:[[:space:]]*"success"'; then
  echo "FAIL: guest_feed did not report success"
  exit 1
fi
echo "PASS: guest_feed returned 200 with success payload"

echo "==> Demo login check"
login_payload="{\"email\":\"$DEMO_EMAIL\",\"password\":\"$DEMO_PASSWORD\"}"
login_output="$(request POST "$BACKEND_BASE_URL/api/v1/auth/login" "$login_payload")"
login_code="$(echo "$login_output" | head -n1)"
login_body="$(echo "$login_output" | tail -n +2)"
if [[ "$login_code" != "200" ]]; then
  echo "FAIL: login returned $login_code"
  echo "$login_body"
  exit 1
fi
if ! echo "$login_body" | grep -Eq '"status"[[:space:]]*:[[:space:]]*"success"'; then
  echo "FAIL: login payload did not report success"
  echo "$login_body"
  exit 1
fi
echo "PASS: login returned 200 with success payload"

echo "==> Auth session check"
auth_output="$(request GET "$BACKEND_BASE_URL/api/v1/auth/is_authenticated")"
auth_code="$(echo "$auth_output" | head -n1)"
auth_body="$(echo "$auth_output" | tail -n +2)"
if [[ "$auth_code" != "200" ]]; then
  echo "FAIL: is_authenticated returned $auth_code"
  exit 1
fi
if ! echo "$auth_body" | grep -Eq '"authenticated"[[:space:]]*:[[:space:]]*true'; then
  echo "FAIL: is_authenticated did not return authenticated=true"
  echo "$auth_body"
  exit 1
fi
echo "PASS: authenticated session confirmed"

echo "==> Frontend check"
frontend_code="$(curl -sS -o "$TMP_DIR/frontend.html" -w "%{http_code}" "$FRONTEND_BASE_URL/")"
if [[ "$frontend_code" != "200" ]]; then
  echo "FAIL: frontend returned $frontend_code"
  exit 1
fi
echo "PASS: frontend returned 200"

echo "Smoke test completed successfully."
