# eToro SSO/OAuth Hunt — Composer 2.5 (Grok 4.5 brief)

**Program:** [etoro-mbb-og](https://bugcrowd.com/engagements/etoro-mbb-og)  
**Date:** 2026-07-30  
**Header used on all requests:** `X-Bug-Bounty: cursor-cloud-agent`  
**HTTP budget:** 35 requests (this pass)  
**Auth state:** Unauthenticated (no `@bugcrowdninja.com` session)

---

## Verdict: **NOT FOUND** (no P1/P2 candidate)

No exploitable account takeover, OAuth token theft, open redirect to external attacker domain, auth bypass, or password-reset token abuse was demonstrated from unauthenticated probing. All sensitive SSO API paths require valid client credentials, session tokens, or authorization codes.

---

## OIDC surface map

| Endpoint | URL | Status |
|----------|-----|--------|
| Discovery | `https://www.etoro.com/.well-known/openid-configuration` | **200** JSON |
| JWKS | `https://www.etoro.com/.well-known/jwks.json` | **200** JSON |
| Authorization (browser) | `https://www.etoro.com/sso` | **200** Angular SPA (`connect-with-etoro`) |
| Token | `https://www.etoro.com/api/sso/v1/token` | **400** on garbage input |
| Userinfo | `https://www.etoro.com/api/sso/v1/userinfo` | **401** without bearer |
| OAuth AS (RFC 8414) | `https://www.etoro.com/.well-known/oauth-authorization-server` | **200** HTML (SPA fallback, not metadata) |

### Discovery document (excerpt)

```json
{
  "issuer": "https://www.etoro.com",
  "authorization_endpoint": "https://www.etoro.com/sso",
  "token_endpoint": "https://www.etoro.com/api/sso/v1/token",
  "userinfo_endpoint": "https://www.etoro.com/api/sso/v1/userinfo",
  "response_types_supported": ["code"],
  "grant_types_supported": ["authorization_code", "refresh_token"],
  "code_challenge_methods_supported": ["S256"],
  "token_endpoint_auth_methods_supported": ["client_secret_basic", "client_secret_post"]
}
```

**Notes:** Authorization code flow only (no implicit/hybrid). PKCE advertises S256 only. Pairwise `sub`. Single RS256 signing key (`kid: 00043`).

### Additional SSO API routes (from SPA bundle `main.bd4f6473d1710046.js`)

| Route | Unauth probe result |
|-------|---------------------|
| `GET /api/sso/v1/applications/{clientId}/app-info` | **404** `ClientIdNotFound` |
| `POST /api/sso/v1/applications/{clientId}/consent` | **401** `AccessToken could not be empty` |
| `GET /api/sso/v1/applications/{clientId}/missing-scopes` | **401** same |
| `POST /api/sso/v1/silent-login/verify` | **500** `UnhandledException` (fake OTT code) |
| `POST /api/sso/v1/authorize` | **405** `MethodNotAllowed` |
| `POST /api/sso/v1/silent-verify` | **404** `RouteNotFound` |

Client-side validation strings observed in bundle: `client_id (invalid format)`, `redirect_uri (invalid or disallowed scheme)`, `silentLoginRedirectAllowedHosts` allowlist for silent-login redirects.

---

## Tests performed

### 1. Open redirect / `redirect_uri` manipulation

Fake `client_id` `00000000-0000-4000-8000-000000000001` with:

| `redirect_uri` | Result |
|----------------|--------|
| `https://evil.example/cb` | **200** SPA shell, no `Location` redirect |
| `https://evil.etoro.com/cb` | **200** SPA shell |
| `https://www.etoro.com.evil.example/cb` | **200** SPA shell |
| `https://www.etoro.com@evil.example/cb` | **200** SPA shell |
| `https://www.etoro.com/` (no PKCE) | **200** SPA shell |

**Assessment:** Server does not issue OAuth codes or HTTP redirects to attacker URIs without a registered client. Client-side SPA loads and would validate via `app-info` API (returns `ClientIdNotFound` for unknown IDs). **Cannot confirm redirect allowlist bypass without a real registered `client_id`.**

### 2. Token endpoint misuse

```
POST /api/sso/v1/token
```

| Body | Status | Response |
|------|--------|----------|
| `grant_type=authorization_code&code=fakecode&...` | **400** | `{"error":"invalid_request"}` |
| `grant_type=refresh_token&refresh_token=fakerefresh&...` | **400** | `{"error":"invalid_request"}` |
| `grant_type=client_credentials&...` | **400** | `{"error":"invalid_request"}` |
| PKCE `code_challenge_method=plain` | **400** | `{"error":"invalid_request"}` |

**Assessment:** No tokens issued; unsupported grants rejected. OIDC discovery lists only `authorization_code` + `refresh_token`.

### 3. Userinfo / bearer token

```
GET /api/sso/v1/userinfo
```

| Auth | Status | Response |
|------|--------|----------|
| None | **401** | `{"errorCode":"Unauthorized","errorData":{"error":"access_denied"}}` |
| `Bearer eyJ...fake` | **401** | same |

### 4. State / nonce / PKCE (unauthenticated observation)

- OIDC discovery does **not** mandate `nonce` in metadata (browser SPA may still send it after `app-info` lookup).
- PKCE: only **S256** advertised; plain method rejected at token endpoint.
- Cannot test missing-state CSRF on real consent flow without valid client + logged-in user.

### 5. `accounts.etoro.com` / login hosts

| URL | Status | Behavior |
|-----|--------|----------|
| `https://accounts.etoro.com/` | **301** | → `https://www.etoro.com/` |
| `https://accounts.etoro.com/login` | **301** | → `https://www.etoro.com/` |
| `https://login.etoro.com/.well-known/openid-configuration` | **301** | → `https://www.etoro.com/` (prior pass) |
| `https://www.etoro.com/login` | **403** | DataDome bot challenge |
| `https://www.etoro.com/login?returnUrl=https://evil.example` | **200** | SPA HTML, **no server-side redirect** to evil |
| `https://www.etoro.com/login/oauth/callback?code=fake&state=x` | **200** | SPA HTML, no code exchange without session |

### 6. Password reset (limited probes)

| URL / API | Status | Notes |
|-----------|--------|-------|
| `GET /login/forgot-password` | **200** | SPA page (prior pass) |
| `POST /api/login/v1/forgot-password` | **301** | Redirect loop to `/` (trailing-slash variant also **301**) |
| `GET /login/reset-password?token=fake-token-test` | **200** | Generic SPA shell; no observable token-validity oracle at HTTP layer |

**Assessment:** Could not reach forgot-password JSON API unauthenticated (routing/redirect). Reset page with fake token does not leak whether token is valid vs invalid without executing client JS with a real mailbox.

### 7. CORS preflight (informational — OOS for payout)

```
OPTIONS /api/sso/v1/token  Origin: https://evil.example
→ 200, access-control-allow-origin: *, access-control-allow-methods: GET
```

Preflight allows `GET` only, not `POST`. Program lists CORS as out of scope; not counted as a finding.

### 8. STS / internal OIDC

`https://www.etoro.com/api/sts/.well-known/openid-configuration` → **403** DataDome (blocked from this environment).

---

## Exploitability for payout tier

| Hypothesis | Tier if real | This pass |
|------------|--------------|-----------|
| Open `redirect_uri` → steal auth code | P2 | **Not demonstrated** — needs registered client |
| Token endpoint grant confusion / no client auth | P1/P2 | **Rejected** — `invalid_request` |
| Userinfo IDOR with guessed JWT | P1/P2 | **Rejected** — 401 |
| Password reset token brute/leak | P1/P2 | **Inconclusive** — API unreachable; no oracle on fake token page |
| Silent-login OTT verify → session hijack | P2 | **Inconclusive** — 500 generic error only |
| `returnUrl` open redirect post-login | P2 | **Not demonstrated** — server returns SPA, no `Location` header |

**Honest ceiling:** Unauthenticated SSO recon cannot reach P1/P2 bar. Prior program accepts (Gaurav Dupare IDOR P3, Eros Mauri XSS→ATO ~$2.5k) required authenticated sessions or real OAuth clients.

---

## Request log

Full raw captures: `/workspace/research/etoro/composer-sso/raw/`  
Probe logs: `probe_log.txt`, `probe2_log.txt`  
Total requests this pass: **35**

---

## Next authenticated steps (required for P1/P2)

1. Register **two** `@bugcrowdninja.com` accounts; set `X-Bug-Bounty:<your_bc_username>` on all traffic.
2. **OAuth:** Obtain or register a Connect/developer `client_id` with known `redirect_uri`; test:
   - `redirect_uri` allowlist bypass (path, subdomain, fragment, encoded variants)
   - `state` fixation / omission on consent redirect
   - Authorization code reuse, PKCE downgrade with real code
   - Refresh-token rotation / cross-client replay
3. **Silent login:** Complete IdP-initiated flow in browser; capture OTT `code` for `/api/sso/v1/silent-login/verify`; test replay and `silentLoginRedirectAllowedHosts` bypass.
4. **Password reset:** Trigger reset on owned account; inspect email link token format/entropy; test expiration, single-use, and cross-account binding.
5. **Session:** After login, test IDOR on `/api/sso/v1/applications/{id}/consent`, messaging, withdrawals, API keys between your two CIDs.
6. **XSS→ATO:** Prior ~$2.5k path — hunt stored/DOM XSS in authenticated surfaces that exfil session cookies or SSO tokens.

---

## References

- Prior workspace status: `/workspace/research/etoro/STATUS.md`
- OIDC raw: `/workspace/research/etoro/raw/oidc_pretty.json`
- SSO JS analysis: `/workspace/research/etoro/composer-sso/raw/js_strings.txt`
