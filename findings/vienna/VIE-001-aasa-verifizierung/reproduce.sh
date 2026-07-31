#!/usr/bin/env bash
set -euo pipefail
UA='Mozilla/5.0 (compatible; BugcrowdResearcher/1.0)'
DIR=$(cd "$(dirname "$0")" && pwd)
curl -sS -A "$UA" 'https://mein.wien.gv.at/.well-known/apple-app-site-association' | tee "$DIR/aasa.json"
echo
curl -sS -A "$UA" 'https://mein.wien.gv.at/api/Account/ActivateAccount?token=bb-research-invalid-token' | tee "$DIR/activate_response.json"
echo
curl -sS -A "$UA" 'https://mein.wien.gv.at/Verifizierung?token=bb-research-invalid-token' \
  | rg -n "window\.VERIFY|token :" | tee "$DIR/token_reflect_lines.txt"
