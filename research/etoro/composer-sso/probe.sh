#!/bin/bash
set -euo pipefail
HDR='X-Bug-Bounty: cursor-cloud-agent'
OUTDIR=/workspace/research/etoro/composer-sso/raw
mkdir -p "$OUTDIR"
LOG="$OUTDIR/probe_log.txt"
REQ=0
: > "$LOG"

probe() {
  local name="$1"; shift
  REQ=$((REQ+1))
  echo "=== REQ#$REQ $name ===" | tee -a "$LOG"
  echo "CMD: $*" | tee -a "$LOG"
  local bodyfile="$OUTDIR/${REQ}_${name}.body"
  local hdrfile="$OUTDIR/${REQ}_${name}.hdr"
  local code
  code=$(curl -sS -D "$hdrfile" -o "$bodyfile" -w '%{http_code}' -H "$HDR" -H 'User-Agent: Mozilla/5.0 (compatible; BugBounty/1.0)' "$@") || true
  echo "http_code=$code size=$(wc -c < "$bodyfile" 2>/dev/null || echo 0)" | tee -a "$LOG"
  head -20 "$hdrfile" 2>/dev/null | tee -a "$LOG" || true
  head -c 500 "$bodyfile" 2>/dev/null | tee -a "$LOG" || true
  echo "" | tee -a "$LOG"
}

# 1 OIDC discovery
probe oidc_discovery "https://www.etoro.com/.well-known/openid-configuration"

# 2 JWKS
probe jwks "https://www.etoro.com/.well-known/jwks.json"

# 3 SSO auth - no params
probe sso_auth_bare "https://www.etoro.com/sso"

# 4 SSO auth - evil redirect_uri
probe sso_auth_evil_redirect "https://www.etoro.com/sso?response_type=code&client_id=00000000-0000-4000-8000-000000000001&redirect_uri=https://evil.example/cb&scope=openid&state=teststate"

# 5 SSO auth - etoro subdomain redirect
probe sso_auth_subdomain_redirect "https://www.etoro.com/sso?response_type=code&client_id=00000000-0000-4000-8000-000000000001&redirect_uri=https://evil.etoro.com/cb&scope=openid&state=teststate"

# 6 SSO auth - @ bypass
probe sso_auth_at_bypass "https://www.etoro.com/sso?response_type=code&client_id=00000000-0000-4000-8000-000000000001&redirect_uri=https://www.etoro.com.evil.example/cb&scope=openid"

# 7 SSO auth - path traversal style
probe sso_auth_path "https://www.etoro.com/sso?response_type=code&client_id=00000000-0000-4000-8000-000000000001&redirect_uri=https://www.etoro.com@evil.example/cb&scope=openid"

# 8 Token endpoint - no auth
probe token_noauth -X POST "https://www.etoro.com/api/sso/v1/token" -H "Content-Type: application/x-www-form-urlencoded" -d "grant_type=authorization_code&code=fakecode&redirect_uri=https://evil.example/cb&client_id=test"

# 9 Token endpoint - refresh token abuse
probe token_refresh -X POST "https://www.etoro.com/api/sso/v1/token" -H "Content-Type: application/x-www-form-urlencoded" -d "grant_type=refresh_token&refresh_token=fakerefresh&client_id=test"

# 10 Token endpoint - client_credentials attempt
probe token_client_cred -X POST "https://www.etoro.com/api/sso/v1/token" -H "Content-Type: application/x-www-form-urlencoded" -d "grant_type=client_credentials&client_id=test&client_secret=test"

# 11 Userinfo no token
probe userinfo_noauth "https://www.etoro.com/api/sso/v1/userinfo"

# 12 Userinfo fake bearer
probe userinfo_fake -H "Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.fake" "https://www.etoro.com/api/sso/v1/userinfo"

# 13 Silent verify endpoint
probe silent_verify -X POST "https://www.etoro.com/api/sso/v1/silent-verify" -H "Content-Type: application/json" -d '{"client_id":"test","redirect_uri":"https://evil.example"}'

# 14 App-info known pattern
probe appinfo_evil "https://www.etoro.com/api/sso/v1/applications/00000000-0000-4000-8000-000000000001/app-info?redirect_uri=https://evil.example/cb&client_request_id=bb-test"

# 15 OPTIONS token CORS
probe token_options -X OPTIONS "https://www.etoro.com/api/sso/v1/token" -H "Origin: https://evil.example" -H "Access-Control-Request-Method: POST"

# 16 accounts.etoro.com
probe accounts_root "https://accounts.etoro.com/"

# 17 accounts login
probe accounts_login "https://accounts.etoro.com/login"

# 18 forgot-password API probe
probe forgot_api -X POST "https://www.etoro.com/api/login/v1/forgot-password" -H "Content-Type: application/json" -d '{"email":"nonexistent-bb-test@bugcrowdninja.com"}'

# 19 reset token probe
probe reset_token "https://www.etoro.com/login/reset-password?token=fake-token-test"

# 20 STS wellknown
probe sts_oidc "https://www.etoro.com/api/sts/.well-known/openid-configuration"

echo "TOTAL_REQ=$REQ" | tee -a "$LOG"
echo "$REQ" > "$OUTDIR/req_count.txt"
