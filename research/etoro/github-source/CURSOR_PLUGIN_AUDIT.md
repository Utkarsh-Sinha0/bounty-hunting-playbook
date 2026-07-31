# eToro Cursor Plugin & Agent-Skills — Bugcrowd Source Audit

**Date:** 2026-07-30  
**Auditor:** Composer 2.5 (read-only source + limited HTTP validation)  
**Repos:**

| Repo | Path | Role |
|------|------|------|
| `eToro-Public/etoro-cursor-plugin` | `/workspace/vendor/etoro-github/etoro-cursor-plugin` | Cursor IDE plugin (rules, skills, MCP config) — **developer integration guidance** |
| `eToro-Public/etoro-agent-skills` | `/workspace/vendor/etoro-github/etoro-agent-skills` | Runtime agent skills — **end-user trading assistant behavior** |

**Scope:** P1/P2 candidates against eToro-owned infra (`*.etoro.com`, Public API, SSO). Third-party MCP servers out of scope unless proven eToro impact.

---

## Executive verdict

**No P1/P2 Bugcrowd candidates identified** in either repository from static analysis and bounded HTTP probes.

One **informational / hardening** item (hardcoded Public API partner key in `etoro-agent-skills`) does **not** meet P1/P2 bar: partner key alone cannot access user accounts; trading still requires a per-user `x-user-key`, agent-portfolio `userToken`, or OAuth Bearer token.

---

## Methodology

1. Full-file inventory of both clones (38 + 39 files; markdown/rules/skills only — no application runtime code).
2. Pattern search: secrets, OAuth, tokens, redirects, internal hosts, auth bypass, auto-trade paths.
3. Manual review of all skills, rules, and reference docs.
4. **8 HTTP probes** to `public-api.etoro.com` with header `X-Bug-Bounty: cursor-cloud-agent` (partner-key validation only; no user credentials used).

---

## Findings table

| ID | Severity (Bugcrowd) | Repo | Location | Summary | Exploit sketch | Status |
|----|---------------------|------|----------|---------|----------------|--------|
| F-01 | Informational (not P1/P2) | `etoro-agent-skills` | `skills/etoro-trading-assistant/references/api-conventions.md:32` | Hardcoded `x-api-key` presented as “canonical eToro Public API partner key” | Attacker copies key from public GitHub → still needs victim `x-user-key` / `userToken` / OAuth token to read portfolio or trade. Partner-only requests return `401 Unauthorized`. | **Not exploitable to P1/P2 without user secret** |
| — | N/A (documented API footgun) | Both | `rules/etoro-sso-identity.mdc`, `references/sso-and-session.md` | `/user-info/people?cidList=` accepts numeric IDs without validating namespace; passing `gcid` or `demoCid` instead of `realCid` silently returns wrong user | Requires **valid authenticated session**; wrong-ID lookup is a developer mistake / API design issue, not an auth bypass introduced by these repos. Docs **warn** integrators. | Out of scope for plugin audit; not a repo vuln |
| — | N/A | `etoro-cursor-plugin` | `skills/building-etoro-api-client/SKILL.md:76-77` | Partner key via `process.env.ETORO_API_KEY` — **no hardcoded secret** | — | Clean |
| — | N/A | `etoro-cursor-plugin` | `.mcp.json` | MCP → `https://api-portal.etoro.com/mcp` (eToro-owned docs server) | — | In scope infra; no secret leakage |

---

## Detailed analysis by hunt category

### 1. Hardcoded API keys / OAuth secrets / user keys

**`etoro-agent-skills` — hardcoded partner key (F-01)**

```32:35:vendor/etoro-github/etoro-agent-skills/skills/etoro-trading-assistant/references/api-conventions.md
x-api-key: sdgdskldFPLGfjHn1421dgnlxdGTbngdflg6290bRjslfihsjhSDsdgGHH25hjf
```

- Labeled “canonical” and “always” for API-key auth; users are told **not** to supply it (`onboarding.md:14`, `README.md:32`).
- Contradicts eToro Builders guidance (“Never hardcode API keys”, per-user keys from Settings → Trading).
- **`etoro-cursor-plugin` does not contain this value**; it uses `process.env.ETORO_API_KEY` in `building-etoro-api-client/SKILL.md`.

**HTTP validation (partner key only, no user key):**

| Endpoint | Partner key only | No auth |
|----------|------------------|---------|
| `GET /api/v1/market-data/search?query=AAPL` | 401 | 401 |
| `GET /api/v1/agent-portfolios` | 401 | 401 |
| `GET /api/v1/me` | 401 | 401 |

Same `401 {"errorCode":"Unauthorized"}` for valid-looking partner key vs wrong partner key + fake user key — cannot confirm key validity without a real user key, but **no unauthenticated data access observed**.

**P1/P2 assessment:** Public API auth is two-factor at the HTTP layer (`x-api-key` + `x-user-key` or Bearer). Leaking the partner/app identifier does not grant account takeover or trading. Worst case: shared rate-limit bucket / partner attribution — **not P1/P2**.

**No** hardcoded `x-user-key`, `userToken`, `client_secret`, refresh tokens, or JWTs found in either repo.

---

### 2. Auth bypass / skip-check patterns on real API

**OAuth (cursor-plugin):** `implementing-etoro-sso/SKILL.md` documents standard auth-code + PKCE:

- `state` verified on callback (`stored.state !== state` → 400).
- `code_verifier` single-use in session.
- `redirect_uri` from `process.env.ETORO_REDIRECT_URI` — no open-redirect recipe.
- Token exchange to fixed host `https://www.etoro.com/sso/oidc/token`.

**No** documented patterns to skip auth, disable TLS, use demo credentials on real endpoints, or omit required headers.

**Agent-portfolio key detection** (`onboarding.md:30`): “Skip Steps 2 and 3 silently” is UX flow optimization when user already has an agent-portfolio key — not an API auth bypass.

---

### 3. SSRF / open redirect in OAuth flows

- Authorize URL is fixed: `https://www.etoro.com/sso/oauth2/authorize`.
- Callback `redirect_uri` is env-configured; sample code validates OAuth `state`.
- No user-controlled redirect targets in samples.
- **No SSRF vectors** (no server-side fetch-to-arbitrary-URL patterns in repo content).

---

### 4. Agent-portfolio delegated token abuse

Documented flow (`onboarding.md`, `etoro-agent-portfolios/SKILL.md`):

1. User provides main-account `x-user-key` with `real:write` **or** existing agent-portfolio `userToken`.
2. Portfolio creation returns `userTokens[0].userToken` **once**; agent must hand off to user for storage.
3. Agent trades with `userToken` as `x-user-key` + canonical partner `x-api-key`.
4. `scopeIds: [202]` documented as `real:write` — no instruction to request elevated scopes.
5. 401 on revoked `userToken` → stop workflow, no refresh, no silent retry.

**No** path to steal another user’s token from the repo itself. Risk is operational (user pastes token into untrusted agent / LLM logs) — outside these markdown artifacts.

---

### 5. Unsafe defaults — AI agents trading real money without confirmation

**Strong guardrails found** (especially `etoro-agent-skills`):

| Control | Location |
|---------|----------|
| Explicit confirmation before open/close/modify | `etoro-trading-assistant/SKILL.md:41`, `single-trade-walkthrough.md:106-136` |
| Auto-execute only after user opt-in | `single-trade-walkthrough.md:136` — “execute automatically for this session” |
| Default `Leverage: 1` | `api-conventions.md:127-128`, `etoro-api-conventions.mdc:153-154` |
| Stop on 401; no hallucinated fills | `execution-invariants.md §4`, `sso-and-session.md` |
| At-most-once on trade POSTs (no blind retry) | `execution-invariants.md §3` |
| Closes require explicit consent when funding new trades | `bulk-trading.md §2`, `rebalancing.md` |
| Conditional rules require structured confirmation before activation | `conditional-rules.md:46-48` |

Auto-rebalance / conditional-rule modes can skip per-trade approval **only** when user has opted into recurring/autonomous behavior — documented, not default-silent trading.

**Assessment:** Product-risk hardening is present; not a clear P2 “unsafe default enables real-money trades without confirmation.”

---

### 6. Leaked internal hostnames / authz bypass enablers

**Only public endpoints referenced:**

- `https://public-api.etoro.com/api/v1`
- `https://www.etoro.com/sso/...` (OAuth/STS)
- `https://api-portal.etoro.com/` (docs + MCP)

**No** internal/staging hostnames (`*.internal`, `*.dev`, private IPs, admin paths) discovered.

---

## `etoro-cursor-plugin` — repo-specific notes

| Asset | Content | Security note |
|-------|---------|---------------|
| `.mcp.json` | `etoro-api-docs` → `api-portal.etoro.com/mcp` | eToro-owned; Cloudflare blocked unauthenticated probe from audit environment |
| Rules (`*.mdc`) | API conventions, SSO identity, account snapshot, ID resolution | Defensive documentation |
| Skills | SSO implementation, API client, session expiry, etoro-apps | Env-based secrets; PKCE + state |
| `plugin.json` | Metadata v1.1.0 | No credentials |

Plugin targets **developers building integrations**, not runtime trading. It does **not** bundle `etoro-agent-skills` or the hardcoded partner key.

---

## `etoro-agent-skills` — repo-specific notes

Runtime trading assistant for LLM agents acting on user behalf. Highest sensitivity:

- Collects user API keys / `userToken` in conversational flow (by design).
- Hardcoded partner key (F-01).
- Extensive safety invariants (`execution-invariants.md`).

---

## HTTP probe log

All requests included `X-Bug-Bounty: cursor-cloud-agent`.

1. `GET public-api.etoro.com/api/v1/market-data/search?query=AAPL` — partner key only → 401  
2. Same — wrong partner key + fake user key → 401  
3. `GET .../market-data/instruments/rates?instrumentIds=1` — partner key only → 401  
4. `GET .../api/v1/me` — partner key only → 401  
5. `GET .../agent-portfolios` — no headers → 401  
6. `GET .../agent-portfolios` — partner key only → 401  
7. `GET api-portal.etoro.com/llms.txt` → Cloudflare block (no content)  
8. `GET api-portal.etoro.com/mcp` → Cloudflare block  

**Total probes: 8** (within ≤15 budget).

---

## Hardening recommendations (non-P1/P2)

1. **Remove hardcoded partner key from `etoro-agent-skills`** — align with `etoro-cursor-plugin` (`ETORO_API_KEY` env) and Builders portal guidance. If a shared platform key is intentional, document it on api-portal.etoro.com and clarify it is a non-secret app identifier with no standalone API access.
2. **Rotate/review canonical key** if it was ever a personal portal-generated Public API Key rather than a dedicated platform identifier.
3. **Agent deployers:** treat `userToken` / `x-user-key` as passwords; never log to LLM providers; use secret stores.
4. **OAuth integrators:** keep `state` + PKCE checks (already documented); register fixed `redirect_uri` values.
5. **API product:** consider server-side rejection when `cidList` receives `gcid`/`demoCid` (documented footgun today).
6. **Split repos clearly** in Bugcrowd scope: cursor-plugin = dev docs; agent-skills = runtime behavior + the only credential-adjacent artifact (F-01).

---

## Conclusion

| Question | Answer |
|----------|--------|
| P1/P2 candidate? | **No** |
| Closest item | F-01 hardcoded `x-api-key` in `etoro-agent-skills` — informational; no demonstrated account or trading impact without user credentials |
| cursor-plugin clean? | **Yes** — no secrets; sound OAuth samples |
| agent-skills trading safety | **Strong** confirmation and execution invariants; partner key hardcoding is the main hygiene gap |

**Recommended Bugcrowd submission:** None from this audit. Optional informational to eToro API team re: F-01 and `cidList` namespace validation on the Public API.
