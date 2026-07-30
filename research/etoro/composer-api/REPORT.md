# eToro Bugcrowd (`etoro-mbb-og`) — Broken Access Control Hunt

**Agent:** Composer 2.5 (Grok 4.5 brief)  
**Date:** 2026-07-30  
**Header:** `X-Bug-Bounty: cursor-cloud-agent` on all requests  
**Scope:** P1/P2 IDOR/BOLA exposing **private** balances, KYC, email/phone, withdrawals, API keys, messages  
**Requests:** ~36 (29 scripted + 6 supplemental + 1 rankings confirm)

---

## Verdict

### **NOT FOUND** — no P1/P2 broken access control in this unauthenticated pass

No endpoint returned private financial data (cash balance, withdrawal history, KYC documents, API keys, inbox messages) or contact PII (email, phone) without authentication. Public copy-trading/social fields remain public-by-design and match prior Bugcrowd tiering (logininfo→CID is OOS; legacy portfolio IDOR was P3).

Authenticated two-account IDOR (billing, withdrawals, KYC, API keys between owned CIDs) was **not testable** here — requires `@bugcrowdninja.com` sessions per program guidance.

---

## Method

1. Read `/workspace/research/etoro/STATUS.md` and prior `raw/` captures (portfolio JSON, logininfo, OIDC).
2. Probed `www.etoro.com` (`/api/*`, `/sapi/*`), `tapi-real`/`tapi-demo`, `public-api`, `uapi-front`, `watchlistapi`, `billing`, `wallet`, `accounts`, `api.etoro.com`.
3. Used **one** well-known public profile for boundary testing: **billgates** (`realCID=17252`, `optOut=true`). Baseline public PI: **JeppeKirkBonde** (`realCID=2988943`).
4. Distinguished social/public fields from private-sensitive targets per mission brief.

---

## Evidence table

| # | Endpoint | Method | Auth | HTTP | Private data? | Notes |
|---|----------|--------|------|------|---------------|-------|
| 1 | `/api/logininfo/v1.1/users/billgates` | GET | None | 200 | **No** | Returns `realCID`, `username`, `country`, `verificationLevel`, `optOut`, `CustomerRestrictions`. **No** email, phone, balance. Social/OOS prior art. |
| 2 | `/api/logininfo/v1.1/users/JeppeKirkBonde` | GET | None | 200 | **No** | Public PI profile: name, bio, avatars, `isPi`, CIDs. By design for copy-trading. |
| 3 | `/api/logininfo/v1.1/users/bbxss9cursor` | GET | None | 404 | **No** | `User … not found` — no enumeration oracle beyond username existence (OOS). |
| 4 | `/api/users/v1/{cid}/personaldetails/` | GET | None | 301→200 HTML | **No** | Redirects to marketing homepage; no JSON PII. Tested CIDs 2988943. |
| 5 | `/api/usermetadata/v1/users/{cid}/` | GET | None | 301→200 HTML | **No** | Same homepage fallback. |
| 6 | `/api/account/v1/users/{cid}/balance` | GET | None | 404 | **No** | Empty body. |
| 7 | `/api/trading/v1/users/{cid}/accountinfo` | GET | None | 301→200 HTML | **No** | Homepage fallback, not account JSON. |
| 8 | `/api/kyc/v1/users/{cid}/status` | GET | None | 301→200 HTML | **No** | Homepage fallback. |
| 9 | `/api/kyc/v1/users/{cid}/documents` | GET | None | 301→200 HTML | **No** | Homepage fallback. |
| 10 | `/api/withdrawal/v1/users/{cid}/requests` | GET | None | 301→200 HTML | **No** | Homepage fallback. |
| 11 | `/api/messages/v1/users/{cid}/inbox` | GET | None | 301→200 HTML | **No** | Homepage fallback. |
| 12 | `/api/publicapi/v1/users/{cid}/keys` | GET | None | 301→200 HTML | **No** | Homepage fallback. |
| 13 | `/api/sso/v1/userinfo` | GET | None | 401 | **No** | `{"errorCode":"Unauthorized"}` |
| 14 | `public-api.etoro.com/api/v1/market-data/instruments` | GET | None | 401 | **No** | Requires API key. |
| 15 | `public-api.etoro.com/api/v1/users/{cid}/portfolio` | GET | None | 401 | **No** | Requires API key. |
| 16 | `billing.etoro.com/api/v1/users/{cid}` | GET | None | 404 | **No** | IIS 404 page. |
| 17 | `wallet.etoro.com/api/v1/users/{cid}/balance` | GET | None | 502 | **No** | Bad gateway; no balance leak. |
| 18 | `uapi-front.etoro.com/api/v1/users/{cid}/profile` | GET | None | 530 | **No** | Origin unreachable (per prior recon). |
| 19 | `watchlistapi.etoro.com/api/v1/watchlists?cid={cid}` | GET | None | 403 | **No** | Cloudflare block. |
| 20 | `accounts.etoro.com/api/v1/users/{cid}` | GET | None | 301→200 HTML | **No** | Marketing homepage. |
| 21 | `tapi-real.etoro.com/api/v1/user/{cid}/portfolio` | GET | None | 404 | **No** | `Internal Server Error` JSON shell. |
| 22 | `tapi-real.etoro.com/api/v1/user/{cid}/account/balance` | GET | None | 404 | **No** | Same. |
| 23 | `/sapi/trade-data/live/public/portfolios?cid={cid}` | GET | None | 404 | **No** | IIS 404 (path may be retired; see prior capture below). |
| 24 | `/sapi/userstats/UserGain/?cid={cid}&Period=OneYearAgo` | GET | None | 404 | **No** | IIS 404 for public PI and billgates. |
| 25 | `/sapi/riskscore/UserRisk/?cid={cid}` | GET | None | 404 | **No** | IIS 404. |
| 26 | `/sapi/trade-data/history/users/{cid}/portfolio/live` | GET | None | 404 | **No** | Legacy IDOR class (prior P3); currently 404 unauth. |
| 27 | `/sapi/rankings/rankings/?PopularInvestor=true&page=1&pageSize=1&Period=OneYearAgo` | GET | None | 200 | **No** | Public PI leaderboard (gain%, copiers, risk scores). Social-by-design. |
| 28 | `api.etoro.com/v1/users/{cid}` | GET | None | 404 | **No** | `Resource not found`. |

Raw artifacts: `/workspace/research/etoro/composer-api/raw/` (plus `logininfo_*.json`, `rankings_ok.json`).

---

## Public vs private — honesty on social-trading design

### Clearly public (not reportable as P1/P2 BAC)

| Surface | Example fields | Why public |
|---------|----------------|------------|
| **logininfo** | `realCID`, `gcid`, `demoCID`, `firstName`/`lastName` (if allowed), `country`, `isPi`, `aboutMe`, avatars | Powers `/people/{username}` and copy-trading discovery. Username→CID is **known/OOS**. |
| **rankings** | `UserName`, `FullName`, gain%, copiers, risk score, `PopularInvestor` | Leaderboard/marketing for PI program. |
| **Prior portfolio capture** (`raw/03_public_portfolio.body`) | `CreditByRealizedEquity`, `AggregatedPositions[].Invested` as **percentages**, instrument IDs | Allocation **weights**, not dollar cash balance. Intended for public PI pages. May 2026 legacy IDOR on similar paths was rated **P3**, not P1. |

### Private targets — none observed unauthenticated

| Target | Expected protection | Observed |
|--------|---------------------|----------|
| Cash / account balance | Session + ownership | 404 or HTML fallback |
| Email / phone | Session / KYC flow | Absent from logininfo; personaldetails → homepage |
| KYC documents | Session | Homepage fallback |
| Withdrawals | Session | Homepage fallback |
| API keys | Session | Homepage fallback |
| Messages / inbox | Session | Homepage fallback |
| SSO userinfo | Bearer token | 401 |
| public-api | API key | 401 |

### billgates boundary case

`billgates` (`realCID=17252`) has `optOut:true`, `allowDisplayFullName:false`, `isPi:false`. logininfo still resolves username→CID (OOS). **No** portfolio/gain/risk JSON was returned via tested `/sapi/*` paths (all 404). This is consistent with privacy controls, not an authz bypass.

---

## Prior art (do not re-report as new P1)

| Finding | Tier | Status this pass |
|---------|------|------------------|
| logininfo username→CID | OOS / social | Confirmed; no email/phone added |
| Legacy API portfolio/stats IDOR (Gaurav Dupare, May 2026) | P3 | `/sapi/trade-data/*` returns 404 unauth now |
| Historical LotCount leak | Fixed | Not reproduced |
| XSS→limited ATO (Eros Mauri, ~$2.5k) | ~P2 | Out of BAC scope; needs authenticated XSS |

---

## What would be needed for P1/P2

1. **Two `@bugcrowdninja.com` accounts** with `X-Bug-Bounty:<bc_username>`.
2. Authenticated IDOR probes: swap CIDs on withdrawals, KYC uploads, API key management, billing, copy-settings, messages.
3. **public-api.etoro.com** with own API keys — test object-level auth on trading/portfolio endpoints.
4. Stored/DOM XSS in authenticated `/app/*` → session theft (prior ~$2.5k path).

---

## Request budget

| Phase | Count |
|-------|-------|
| `probe.sh` | 29 |
| `probe` supplemental (`log2.txt`) | 6 |
| Rankings confirm | 1 |
| **Total** | **~36** |

---

## Conclusion

Unauthenticated probing across sapi, tapi, wallet, billing, public-api, uapi-front, watchlistapi, and sensitive `/api/*` paths did **not** surface private balances, contact PII, KYC, withdrawals, API keys, or messages. Observable data aligns with eToro’s public social/copy-trading model. **P1/P2 BAC not found** in this pass; continue on authenticated two-account testing locally.
