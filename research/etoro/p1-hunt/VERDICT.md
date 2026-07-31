# P1 hunt verdict (2026-07-30)

## Verdict: **NO P1 FOUND**

After live unauth, GitHub source, Composer×N, and under-tested targets (Delta / wallet / openbook / etorox):

| Target | Subs | Result |
|--------|------|--------|
| `*.etoro.com` | 25 | Hardened unauth; needs dual login for IDOR/ATO |
| `delta.app` / `api.getdelta.io` | 1 | Auth required; Firebase locked; no open buckets |
| `io.getdelta.*` | 0–1 | APK not decompiled here (no jadx); API 401 |
| `com.etoro.wallet` | 0 | Marketing page only from this pass |
| `com.etoro.openbook` | 2 | Not separately exploitable unauth |
| `etorox.com` | 0 | Redirects to www.etoro.com |

## What “Known Issues → P1” on Bugcrowd means

That screen is a **counter legend**, not a list of bugs you can copy. Unique/Total counts hide details from other researchers. You cannot “open a known P1” and re-submit it.

## What would actually be P1 here ($6–15k)

- Account takeover of **other** users (session/token theft that works without their password)
- Auth bypass to withdraw / trade / read KYC/PII of others
- RCE / SQLi with data access on eToro infra

None of that was demonstrated. Claiming one without proof = ban + $0.

## Only realistic next step

Your machine + **2 free** `@bugcrowdninja.com` accounts + Burp + `X-Bug-Bounty` → authenticated IDOR / XSS→ATO. That is how prior ~$2.5k (P2-ish) XSS→ATO was found — not from GitHub docs or unauth cloud recon.
