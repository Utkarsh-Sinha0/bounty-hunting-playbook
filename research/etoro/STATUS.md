# eToro Bugcrowd hunt — status (2026-07-30)

## Program snapshot

| | |
|--|--|
| Engagement | [etoro-mbb-og](https://bugcrowd.com/engagements/etoro-mbb-og) |
| P1 | $6,000 – $15,000 |
| P2 | $1,500 – $6,000 |
| P3 | $500 – $1,000 |
| P4 | $100 – $500 |
| Avg payout (3 mo) | **~$738** (mostly P3/P4) |
| Recent CrowdStream | Many **P4** accepts |

## This cloud pass — P1/P2 found?

**No.** Unauthenticated recon only (no `@bugcrowdninja.com` session). P1/P2 on eToro almost always need **two owned accounts** + authenticated IDOR / ATO / XSS→session theft.

### Checked (safe, low volume, `X-Bug-Bounty` set)

- OIDC discovery + JWKS + token endpoint (rejects garbage — no open grant)
- Legacy hosts: `tapi-real/demo`, `uapi-front` (530), `billing`→www, `wallet`→crypto wallet
- Portfolio/sapi probes: private users correctly return `"user is PRIVATE"` / 401/403/404
- Partners WP: user listing **401** (locked); xmlrpc/wp-login **403**
- Public logininfo username→CID: **known / social-by-design**; enum is **OOS**

### Prior art (do not re-report as original P1)

| Public finding | Typical tier |
|----------------|--------------|
| Legacy API IDOR (portfolio/stats) — Gaurav Dupare May 2026 | **P3** |
| XSS → limited ATO — Eros Mauri Jun 2026 | **~$2.5k** (~P2 mid) |
| Historical LotCount leak | Fixed long ago |

## What actually produces P1/P2 here

1. Register **2** accounts with `@bugcrowdninja.com` + send `X-Bug-Bounty:<your_bc_username>` on all traffic.
2. Hunt **authenticated**:
   - IDOR on messages, withdrawals, KYC docs, API keys, billing, copy-settings between your two CIDs
   - OAuth `redirect_uri` / token theft on real registered clients
   - Stored/DOM XSS in authenticated surfaces → session cookie / token theft (prior $2.5k path)
   - Broken object-level auth on `public-api.etoro.com` with your own API keys
3. Avoid OOS: rate-limit, clickjacking, CORS, self-XSS, user enum, DoS, WordPress low/medium.

## Money realism

- **P1 ($6–15k):** rare; needs clear ATO / fund-moving / mass private PII.
- **P2 ($1.5–6k):** achievable with strong XSS→ATO or authz to sensitive actions; recent public example ~$2.5k.
- **Most paid reports ≈ P3/P4** → matches **$738 average**.

## Next step (on your machine)

Do **not** open GitHub issues at eToro. Keep notes local. Authenticated testing from your laptop with Bugcrowd Ninja accounts is required before any P1/P2 claim.
