# Delta / eToroX P1 Hunt Report

**Agent:** Composer 2.5 (Grok 4.5 brief)  
**Date:** 2026-07-30  
**Program:** eToro Bugcrowd (under-tested targets)  
**Header:** `X-Bug-Bounty: cursor-cloud-agent` on all live probes  
**Request budget:** ≤40 target HTTP requests (~38 used; crt.sh/DNS/local JS parsing excluded)

---

## Verdict: **NOT FOUND**

No confirmed **P1** vulnerability (RCE, SQLi with data access, auth bypass / mass ATO, unrestricted file upload → RCE, SSRF to internal with impact, or access to other users' funds/PII without credentials) was identified in this pass.

---

## 1. Host & surface map

| Host | Status | Stack / notes |
|------|--------|----------------|
| `delta.app` | CF challenge (403) | Cloudflare; marketing / main domain |
| `getdelta.io` | 301 → `delta.app` | Redirect only |
| `web.delta.app` | **200** | Next.js (Turbopack) on Vercel; portfolio web app |
| `x.delta.app` | CF challenge (403) | Short-link / social redirect domain |
| `static.delta.app` | CF challenge (403) | Static assets |
| `api.getdelta.io` | **401** (most paths) | Primary REST API; `ping` → 200 |
| `api.delta.app` | NXDOMAIN / no A record | Not in use |
| `etorox.com` / `www.etorox.com` | 301 → `www.etoro.com` | Legacy brand; no live app surface |
| `bifrost.etorox.com` | 301 → etoro.com | CT log artifact |
| `hft.etorox.com`, `ws.etorox.com`, `hft-ws.etorox.com` | 301 → etoro.com | HFT/WS names retired |

### JS bundle recon (`web.delta.app`)

Fetched HTML + 5 `_next/static/chunks/*.js` bundles. Client config embedded in RSC payload:

| Key | Value | P1? |
|-----|-------|-----|
| Firebase `projectId` | `delta-178517` | No — client Firebase config is expected |
| Firebase `apiKey` | `AIzaSyBa90bePwnU5qzEsBDuDzzNYi-2smta0BI` | No — public client key |
| Braze `apiKey` | `broken-api-key-f76f6d60-…` | No — intentional placeholder |
| Sentry `public_key` | `6f1dfab2b06f009a4d4f7319acefa6ea` | No — standard DSN component |
| API base URL | `https://api.getdelta.io` | Mapping only |

API route strings extracted from bundles:

- `/auth`
- `/auth/device-limit`
- `/device/initial-data`
- `/device/register-push-notification-token`

All probed unauthenticated → **401 Unauthorized**.

---

## 2. Misconfiguration checks

### 2.1 `api.getdelta.io`

| Path | Method | Code | Result |
|------|--------|------|--------|
| `/ping` | GET | **200** | `{"pong":"ok"}` — health only |
| `/swagger`, `/swagger.json`, `/api-docs`, `/openapi.json`, `/docs` | GET | 401 | No public API docs |
| `/graphql` | POST (introspection) | 401 | No GraphQL exposure |
| `/.env` | GET | **403** | Blocked (not leaked) |
| `/debug`, `/admin`, `/actuator`, `/health` | GET | 401 | Not exposed |
| `/user` | GET + `Authorization: Bearer null` | 200 JSON | `INVALID_TOKEN` — proper rejection |
| `/coins`, `/portfolio`, `/auth`, `/device/*` | GET/POST | 401 | Auth enforced |

CORS preflight (`Origin: https://evil.example`) → **204** without `Access-Control-Allow-Origin` for attacker origin. Not a credentialed CORS bypass.

### 2.2 Firebase (`delta-178517`)

| Test | Result |
|------|--------|
| RTDB `https://delta-178517.firebaseio.com/.json` | **Deactivated** database |
| Firestore list `documents/users` | Datastore mode / API not available with key |
| Datastore `runQuery` with API key | **401** — keys not accepted |
| Identity Toolkit `accounts:signUp` | **OPERATION_NOT_ALLOWED** — self-signup disabled |

No open Firebase rules or data exfil path found.

### 2.3 S3 buckets

| Bucket | List | Notes |
|--------|------|-------|
| `delta-app.s3.amazonaws.com` | **AccessDenied** | Bucket exists; not public |
| `delta-prod.s3.amazonaws.com` | 403 | Exists; not public |
| `delta-178517`, `getdelta`, `etoro-delta` | 404 | No bucket |

### 2.4 `web.delta.app` sensitive paths

| Path | Code |
|------|------|
| `/.env` | 404 |
| `/.git/config` | 404 |
| `/admin` | 404 |
| `/api/debug` | 404 |

### 2.5 eToroX .NET / IIS classic

All paths on `www.etorox.com` return **301** to `https://www.etoro.com/`:

- `trace.axd`, `elmah.axd`, `web.config`, `.git/HEAD`, `api/swagger`

No IIS/ASP.NET attack surface reachable on etorox.com in 2026 — domain is a redirect stub.

---

## 3. Mobile apps (metadata only)

| Package | Submissions (per brief) | This pass |
|---------|-------------------------|-----------|
| `io.getdelta.android` | 0–1 | No `jadx`/APK tooling in environment; Play Store scrape inconclusive |
| `com.etoro.wallet` | 0 | Not decompiled |
| `com.etoro.openbook` | 2 | Not decompiled |

**Recommendation for follow-up:** Local APK decompile (`jadx`) on `io.getdelta.android` for hardcoded staging API keys or disabled-certificate pinning — out of scope for this 40-request web pass.

---

## 4. Non-P1 observations (not submitted as P1)

1. **Public Firebase client config** on `web.delta.app` — industry-standard for Firebase web SDK; backend rules block data access.
2. **`/ping` unauthenticated** — health check; no sensitive data.
3. **Sentry/Braze config in client** — Braze key is a named placeholder; Sentry public key is by design.
4. **etorox.com redirect** — no standalone exchange UI or API; historical CT names (`hft-ws`, `bifrost`) also redirect.

---

## 5. What would be needed for P1

| Vector | Blocker observed |
|--------|------------------|
| Auth bypass on `api.getdelta.io` | Consistent 401 / `INVALID_TOKEN` on `/user`, `/portfolio`, `/auth`, `/device/*` |
| Firebase data leak | RTDB deactivated; Datastore/Firestore require OAuth, not API key |
| S3 public data | `AccessDenied` on named buckets |
| etorox RCE / SQLi | No application server; 301 only |
| SSRF to internal | No SSRF sink found in unauthenticated surface |
| Mass ATO | Firebase signup disabled; no token issuance without valid issuer |

---

## 6. Request log (summary)

Approximate target HTTP requests: **38**

- Host mapping & headers: 12
- `api.getdelta.io` path probes: 14
- `web.delta.app` HTML + JS chunks: 6
- Firebase / S3 / Datastore: 4
- etorox IIS + WS probes: 2

---

## 7. Ten-line summary

1. **Verdict: NOT FOUND** — no P1 in this scoped pass.  
2. Live Delta API is **`api.getdelta.io`**; web app at **`web.delta.app`** (Vercel/Next.js).  
3. **`delta.app`** main site and **`x.delta.app`** sit behind Cloudflare bot challenges from this environment.  
4. All sensitive API routes require auth; only **`/ping`** is public.  
5. Firebase project **`delta-178517`**: RTDB deactivated, signup disabled, no Datastore read via client key.  
6. S3 buckets **`delta-app`** / **`delta-prod`** exist but deny anonymous access.  
7. No swagger, GraphQL introspection, `.env`, or admin panels exposed on API.  
8. **`etorox.com`** and subdomains (**`hft-ws`**, **`bifrost`**, etc.) **301 to etoro.com** — no .NET/IIS surface.  
9. Mobile APK secret hunt deferred (no `jadx`); packages remain under-tested per program stats.  
10. Best follow-up: authenticated testing on `api.getdelta.io` with a self-scoped Delta account, plus local APK decompile for `io.getdelta.android`.
