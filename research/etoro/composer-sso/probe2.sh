#!/bin/bash
HDR='X-Bug-Bounty: cursor-cloud-agent'
OUTDIR=/workspace/research/etoro/composer-sso/raw
LOG="$OUTDIR/probe2_log.txt"
REQ=20
: > "$LOG"

probe() {
  local name="$1"; shift
  REQ=$((REQ+1))
  echo "=== REQ#$REQ $name ===" | tee -a "$LOG"
  echo "CMD: $*" | tee -a "$LOG"
  local bodyfile="$OUTDIR/${REQ}_${name}.body"
  local hdrfile="$OUTDIR/${REQ}_${name}.hdr"
  local code
  code=$(curl -sS -L --max-redirs 0 -D "$hdrfile" -o "$bodyfile" -w '%{http_code}' -H "$HDR" -H 'User-Agent: Mozilla/5.0 (compatible; BugBounty/1.0)' "$@") || true
  echo "http_code=$code size=$(wc -c < "$bodyfile" 2>/dev/null || echo 0)" | tee -a "$LOG"
  head -15 "$hdrfile" 2>/dev/null | tee -a "$LOG" || true
  head -c 600 "$bodyfile" 2>/dev/null | tee -a "$LOG" || true
  echo "" | tee -a "$LOG"
}

# 21 authorize API direct
probe authorize_evil -X POST "https://www.etoro.com/api/sso/v1/authorize" -H "Content-Type: application/json" -d '{"client_id":"00000000-0000-4000-8000-000000000001","redirect_uri":"https://evil.example/cb","response_type":"code","scope":"openid","state":"x"}'

# 22 silent-login verify
probe silent_login_verify -X POST "https://www.etoro.com/api/sso/v1/silent-login/verify" -H "Content-Type: application/json" -d '{"code":"fake-ott-code"}'

# 23 forgot-password trailing slash
probe forgot_api_slash -X POST "https://www.etoro.com/api/login/v1/forgot-password/" -H "Content-Type: application/json" -d '{"email":"nonexistent-bb-test@bugcrowdninja.com"}'

# 24 token auth code with PKCE plain
probe token_pkce_plain -X POST "https://www.etoro.com/api/sso/v1/token" -H "Content-Type: application/x-www-form-urlencoded" -d "grant_type=authorization_code&code=fake&redirect_uri=https://evil.example&client_id=fake&code_verifier=plain&code_challenge_method=plain"

# 25 consent endpoint
probe consent_noauth -X POST "https://www.etoro.com/api/sso/v1/applications/00000000-0000-4000-8000-000000000001/consent" -H "Content-Type: application/json" -d '{"scopes":["openid"]}'

# 26 missing-scopes
probe missing_scopes "https://www.etoro.com/api/sso/v1/applications/00000000-0000-4000-8000-000000000001/missing-scopes?scope=openid"

# 27 etoro-connect public JS
probe etoro_connect_js "https://cdn.etorostatic.com/latest/js/embed/etoro-connect/etoro-connect.js"

# 28 login page
probe login_page "https://www.etoro.com/login"

# 29 oauth callback common path
probe oauth_cb "https://www.etoro.com/login/oauth/callback?code=fake&state=x"

# 30 open redirect login returnUrl
probe login_returnurl "https://www.etoro.com/login?returnUrl=https://evil.example"

# 31 SSO with PKCE no challenge
probe sso_no_pkce "https://www.etoro.com/sso?response_type=code&client_id=00000000-0000-4000-8000-000000000001&redirect_uri=https://www.etoro.com/&scope=openid&state=x"

# 32 logout/session
probe logout "https://www.etoro.com/api/sso/v1/logout"

# 33 introspect guess
probe introspect -X POST "https://www.etoro.com/api/sso/v1/introspect" -H "Content-Type: application/x-www-form-urlencoded" -d "token=fake"

# 34 revoke guess
probe revoke -X POST "https://www.etoro.com/api/sso/v1/revoke" -H "Content-Type: application/x-www-form-urlencoded" -d "token=fake"

# 35 .well-known oauth-authorization-server
probe oauth_as "https://www.etoro.com/.well-known/oauth-authorization-server"

echo "TOTAL_REQ=$REQ" | tee -a "$LOG"
