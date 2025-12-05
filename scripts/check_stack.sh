#!/bin/sh
set -e
echo "[1] Check Gateway health..."
curl -sf http://localhost:8080/health && echo "Gateway OK"
echo "[2] Create test account in Nakama and get token..."
AUTH_RES=$(curl -s -X POST http://localhost:7350/v2/account/authenticate/email -H 'Content-Type: application/json' -d '{ "email":"test@example.com", "password":"pass", "create": true }' -u "defaultkey:" )
echo "Auth response: $AUTH_RES"
TOKEN=$(echo $AUTH_RES | python3 -c "import sys,json; print(json.load(sys.stdin).get('token',''))")
if [ -z "$TOKEN" ]; then echo "Failed to get token"; exit 1; fi
echo "TOKEN=${TOKEN:0:30}..."
if command -v websocat >/dev/null 2>&1; then
  echo '{"t":"ping"}' | websocat -H "Authorization: Bearer $TOKEN" -n ws://localhost:8080/ws || true
else
  echo "websocat not installed; test WS manually."
fi
