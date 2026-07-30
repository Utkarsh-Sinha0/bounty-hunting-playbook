# eToro Bug Bounty — Composer XSS Hunt Report

**Program:** [etoro-mbb-og](https://bugcrowd.com/engagements/etoro-mbb-og)  
**Date:** 2026-07-30  
**Header:** `X-Bug-Bounty: cursor-cloud-agent`  
**Requests used:** 34 / ~35 budget  
**Verdict:** **NOT FOUND** — no P1/P2 candidate from unauthenticated XSS / partners / delta surfaces

---

## Executive summary

Unauthenticated, low-volume probing of `etoropartners.com`, `delta.app`, `etorox.com`, and reflected parameters on `www.etoro.com` did **not** surface an exploitable XSS→ATO or other P1/P2 issue. WordPress admin/write paths are locked; main eToro properties are behind Cloudflare/DataDome with SPA shells that do not server-reflect query params. Prior paid XSS→ATO path (~$2.5k) requires **authenticated** DOM XSS hunting with two `@bugcrowdninja.com` accounts — not reachable from this pass.

---

## Methodology

| Area | Tests |
|------|-------|
| etoropartners.com | WP REST root, users, plugins, media, pages, redirection/wordfence/wpe_sign_on namespaces, xmlrpc, async-upload, `?s=` reflection + XSS payload |
| delta.app / etorox | Root, `/etoro`, api.etorox.com |
| www.etoro.com | `search`, `referral`, `locale`, `login?redirect`, `sso?next`, `markets?search`, `discover/people?q`, `people/{user}`, `TJoin`, `utm_source`, `forgot-password?email` |
| API | `logininfo` with marker username |

Artifacts: `/workspace/research/etoro/composer-xss/raw/` (bodies, headers, `log.txt`, `log2.txt`).

---

## Findings (none P1/P2)

### 1. etoropartners.com — reflected search (encoded, not exploitable)

**URL:** `https://etoropartners.com/?s=<query>`

**Evidence:** Marker `bbxss9cursor` reflected in `<title>`, `og:title`, JSON-LD, and `href` query strings (REQ#32). XSS probe `bb"><svg/onload=alert(1)>` (REQ#34) returned HTML-encoded output:

```html
<title>You searched for bb&quot;&gt;&lt;svg/onload=alert(1)&gt; - eToro Partners</title>
<meta property="og:title" content="You searched for bb&quot;&gt;&lt;svg/onload=alert(1)&gt; - eToro Partners" />
```

JSON-LD uses `\&quot;` / escaped slashes. No raw markup injection observed.

**Impact:** Informational at most. Program notes WordPress low/medium OOS unless CRITICAL/HIGH; this is standard encoded reflection.

### 2. etoropartners.com — WP REST hardening

| Endpoint | Code | Notes |
|----------|------|-------|
| `/wp-json/wp/v2/users` | 401 | `rest_user_cannot_view` |
| `/wp-json/wp/v2/plugins` | 401 | `rest_cannot_view_plugins` |
| `/wp-json/redirection/v1/*` | 401 | Admin-only |
| `/wp-json/wordfence/v1/config` | 401 | Auth required |
| `/xmlrpc.php` | 403 | nginx block |
| `/wp-admin/async-upload.php` | 403 | Redirect to login, then 403 |
| `/wp-json/wp/v2/posts?_embed` | 418 | WAF/rate signal after burst |

Public: `/wp-json/` (discovery), `/wp-json/wp/v2/pages`, `/wp-json/wp/v2/media` — read-only marketing content. Plugins visible in namespace list (Yoast 28.1, Wordfence, WPML, Redirection, WPE) — version fingerprint only.

**Impact:** No unauth write/RCE/upload path found.

### 3. www.etoro.com — no server-side reflection; WAF on suspicious params

| URL / param | Code | Reflection |
|-------------|------|------------|
| `/search/?q=` | 403 | Cloudflare block on payload |
| `/?locale=` | 403 | CF block |
| `/sso/?next=` | 403 | CF block |
| `/?utm_source=` (with `"onmouseover`) | 403 | CF block |
| `/login/?redirect=` | 200 | Generic SPA shell; **no** `bbxss9cursor` in body |
| `/markets/?search=` | 200 | Same shell; no reflection |
| `/discover/people?q=` | 200 | Same shell; no reflection |
| `/people/bbxss9cursor` | 200 | Same shell; no reflection |
| `/login/forgot-password?email=` | 200 | Same shell; no reflection |
| `/referral/?ref=` | 404 | IIS 404 page |
| `/TJoin/?ref=` | 404 | IIS 404 |

CSP on login: `frame-ancestors 'self' file://*` (clickjacking OOS per program).

**Impact:** No reflected XSS candidate without bypassing DataDome/CF and without client-side DOM analysis (prior $2.5k path).

### 4. delta.app — unreachable

`https://delta.app/` and `/etoro` → **403** Cloudflare challenge (`Just a moment...`). No auth/XSS surface tested.

### 5. etorox.com — deprecated redirect

`www.etorox.com` and `api.etorox.com` → **301** to `https://www.etoro.com/`. No distinct attack surface.

### 6. logininfo API

`GET /api/logininfo/v1.1/users/bbxss9cursor` → 404 JSON `User bbxss9cursor not found`. Marker only in JSON error string (encoded context). Username→CID enum known/OOS.

---

## P1/P2 gap analysis

| Prior paid pattern | This pass |
|--------------------|-----------|
| DOM XSS → limited ATO (~$2.5k) | Requires logged-in session + JS sink tracing in `/app/*`, messages, portfolio widgets |
| Legacy API IDOR (P3) | Private users return 401/403/`user is PRIVATE` (prior recon) |
| OAuth redirect theft | `app-info` rejects unknown client IDs; no open redirect on `redirect`/`next` without auth flow |

**Authenticated next steps (out of scope for cloud unauth pass):**

1. Two `@bugcrowdninja.com` accounts + `X-Bug-Bounty:<bc_username>`.
2. DOM XSS in `/app/*`, copy-trading, feed, messages — trace `location.search`, `postMessage`, `innerHTML` in bundled JS.
3. IDOR between owned CIDs on billing, withdrawals, KYC, API keys.
4. Partners portal `por.etoro.com` (login linked from etoropartners.com) — separate auth surface.

---

## Request log (summary)

```
REQ#1-20  probe.sh  — partners WP, delta, etorox, etoro reflection batch
REQ#21-33 probe2.sh — WP plugin unauth, TJoin, portfolio, utm, partners search
REQ#34    partners_xss — encoded XSS validation on ?s=
```

---

## Conclusion

**P1/P2 candidate: NOT FOUND.**

Best unauthenticated signal: **encoded** search reflection on `etoropartners.com` (not XSS). Main eToro XSS→ATO surface remains **authenticated client-side** per program history and STATUS.md. Recommend continuing hunt from local browser with Bugcrowd Ninja accounts.
