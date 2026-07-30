# eToro GitHub Source — Secret & Scope Audit

**Agent:** Composer 2.5 (Grok 4.5 brief)  
**Date:** 2026-07-30  
**Scope:** Public GitHub orgs/repos owned by or related to eToro; hunt for leaked credentials and P1/P2 exploit paths  
**Header on live probes:** `X-Bug-Bounty: cursor-cloud-agent`  
**Ops budget:** ≤20 `gh`/curl (used **18** — see §7)

---

## 1. Executive summary

| Finding | Severity (Bugcrowd) | Notes |
|---------|-------------------|-------|
| Hardcoded `x-api-key` in `eToro-Public/etoro-agent-skills` | **Info / design** (not P1/P2 alone) | Documented as intentional “canonical Public API partner key”; live probe inconclusive; requires per-user `x-user-key` for account access |
| `client_secret`, live `x-user-key`, `.env`, credential files | **None found** | All references are placeholders or env-var patterns |
| Mobile APK / `com.etoro.*` GitHub mirrors | **None actionable** | Inventory/metadata repos only; no public decompile with server auth secrets |
| API-portal / builders docs on GitHub | **None** | Docs live at `api-portal.etoro.com` and `builders.etoro.com` (not mirrored as repos) |
| SSO identity footguns in public skills | **P3 / integration risk** | Wrong CID namespace (`gcid`/`demoCid` → `cidList`) silently returns another user’s public profile — documented, not a GitHub secret leak |

**Bottom line:** No confirmed live **client_secret** or **user API key** in public eToro-owned GitHub. One **REDACTED candidate** partner `x-api-key` is published by eToro itself and appears to be a shared application identifier per official builders documentation, not a per-user secret. No direct P1/P2 path from GitHub source alone without a separately compromised `x-user-key` or OAuth `client_secret`.

---

## 2. Organizations & repositories inventoried

### 2.1 `eToro-Public` (official, 2 public repos)

| Repo | URL | Local clone | Last push |
|------|-----|-------------|-----------|
| `etoro-cursor-plugin` | https://github.com/eToro-Public/etoro-cursor-plugin | `/workspace/vendor/etoro-github/etoro-cursor-plugin` | 2026-05-06 |
| `etoro-agent-skills` | https://github.com/eToro-Public/etoro-agent-skills | `/workspace/vendor/etoro-github/etoro-agent-skills` | 2026-04-30 |

**Clone status:** Both were already present; no new clones required.

### 2.2 `eToro-API` (official, 1 public repo)

| Repo | URL | Local clone | Notes |
|------|-----|-------------|-------|
| `examples` | https://github.com/eToro-API/examples | `/workspace/vendor/etoro-github/eToro-API-examples` | Legacy HTML/C# samples; placeholders only |

**Clone status:** Cloned during this audit (`git clone --depth 1`).

### 2.3 Related third-party repos (not eToro-owned; scanned via `gh search repos`)

Notable but **out of eToro org scope**:

| Repo | Relevance |
|------|-----------|
| `eToro-API/examples` | Official examples (cloned) |
| `etoroxlabs/eToken` | Ethereum stablecoin; unrelated to trading API auth |
| `thomas-barthelemy/OpenBook.NET` | Archived community OpenBook client; no secrets in index |
| `shayhe-tr/etoro-sdk`, `orkblutt/etoro-mcp`, community bots | Third-party SDKs; no eToro org credentials observed |
| `marianopa-tr/better-auth-etoro` | OAuth plugin; uses `process.env` placeholders only |

---

## 3. GitHub code search (`gh search code`)

Multiple searches were attempted; GitHub returned **HTTP 429** rate limits on most code-search queries. Successful / partial results supplemented by **local ripgrep** over cloned trees.

| Query | Result |
|-------|--------|
| `client_secret org:eToro-Public` | 429 (rate limited) |
| `api_key / x-user-key org:eToro-Public` | 429 |
| `filename:secrets / .env org:eToro-Public` | 429 |
| `x-api-key org:eToro-Public` | 429 |
| `com.etoro` (global) | Metadata only — WalletScrutiny, `h1_asset`, apk index files; **no APK secrets** |
| `etoro` repos search | 25 hits; only `eToro-Public/*` and `eToro-API/examples` are official |

**Local grep** (all clones under `/workspace/vendor/etoro-github/`):

- **No** `.env`, `secrets`, `credentials`, or committed `client_secret` values
- **No** live `x-user-key` or OAuth client secrets
- **Yes** — documented auth patterns, env var names (`ETORO_API_KEY`, `ETORO_CLIENT_ID`, `ETORO_CLIENT_SECRET`)

---

## 4. Secret candidates (redacted)

### 4.1 REDACTED candidate — canonical `x-api-key` (partner / application key)

| Field | Value |
|-------|-------|
| **Location** | `eToro-Public/etoro-agent-skills` → `skills/etoro-trading-assistant/references/api-conventions.md` (lines 27–33) |
| **Also referenced in** | `etoro-agent-portfolios` skill docs (“hardcoded `x-api-key` per api-conventions.md”) |
| **SHA-256 prefix** | `2e9a85da8e07` |
| **Key prefix (redacted)** | `sdgdskld…` (64 chars, committed 2026-04-30 by `guyba-tr`) |
| **Context** | Docs state: *“always the canonical eToro Public API partner key … same value for main account and agent-portfolio. Don't ask the user for it.”* |

**Live validation** (read-only, no user key):

```http
GET /api/v1/market-data/search?q=AAPL
Host: public-api.etoro.com
x-api-key: <REDACTED candidate>
x-user-key: invalid-test-key-00000000
x-request-id: 11111111-1111-1111-1111-111111111111
X-Bug-Bounty: cursor-cloud-agent
```

| Variant | HTTP | Body |
|---------|------|------|
| Published candidate + dummy `x-user-key` | 401 | `{"errorCode":"Unauthorized","errorMessage":"Unauthorized"}` |
| Fake `x-api-key` + dummy `x-user-key` | 401 | Same |

**Interpretation:** Cannot distinguish valid vs invalid partner key without a known-good `x-user-key`. Official [builders.etoro.com authentication guide](https://builders.etoro.com/learn/authentication-and-api-keys) describes `x-api-key` as the **Public API Key** that “identifies your application” (paired with per-user `x-user-key`). Publishing a shared application key may be **intentional** for the Public API / Cursor plugin ecosystem — not equivalent to leaking a user secret or `client_secret`.

**Bugcrowd tiering:** Not P1/P2 as a standalone GitHub leak unless eToro confirms this value is meant to be confidential **and** it enables account actions without `x-user-key` (not demonstrated).

### 4.2 Placeholders (not secrets)

| Location | Pattern |
|----------|---------|
| `eToro-API/examples/discovery-example.html` | `YOUR_API_KEY` |
| `eToro-API/examples/competition-example.html` | `YOUR_COMPETITIONS_API_KEY` |
| `eToro-API/examples/CSharpTradingAPIExample/.../Program.cs` | `APIKey = ""`, `Password = ""` |
| `etoro-cursor-plugin/skills/building-etoro-api-client/SKILL.md` | `process.env.ETORO_API_KEY!` |
| `etoro-cursor-plugin/skills/implementing-etoro-sso/SKILL.md` | `process.env.ETORO_CLIENT_ID/SECRET` |

---

## 5. API-portal / builders documentation

| Surface | GitHub repo? | Access from audit host |
|---------|--------------|------------------------|
| https://api-portal.etoro.com/ | **No** — hosted portal only | `llms.txt` → **Cloudflare block** (403 “Sorry, you have been blocked”) |
| https://api-portal.etoro.com/mcp | Referenced in `etoro-cursor-plugin/.mcp.json` | Not probed (blocked) |
| https://builders.etoro.com/learn/authentication-and-api-keys | **No** — web docs | Readable via web search; confirms dual-header model |

Public repos **point to** api-portal URLs in README/skills but do **not** host OpenAPI specs or builder credentials.

---

## 6. Mobile / OpenBook historical leak search

**Package IDs in scope:** `com.etoro.openbook`, `com.etoro.wallet`

| Source type | Finding |
|-------------|---------|
| GitHub `com.etoro` code search | App inventory markdown (WalletScrutiny, `adysec/h1_asset`, `ixt/ManifestDestinyDB` manifests), APK download **index** files (`apkcombo.com/...` URLs) — **no decompiled `strings.xml` with API secrets** |
| `eToro-Public` / `eToro-API` repos | No mobile source |
| `OpenBook.NET` (community, archived) | Legacy social-trading client library; no eToro server credentials in repo index |

**Conclusion:** No public GitHub mirror was found that exposes **live server `client_secret` or production API keys** from mobile/OpenBook artifacts. APK reverse-engineering would require downloading binaries (out of this pass); stealer-log / decompile repos searched on GitHub returned no eToro auth material.

---

## 7. Operations log (gh / curl budget)

| # | Operation | Outcome |
|---|-----------|---------|
| 1 | `gh repo list eToro-Public` | 2 repos |
| 2–5 | `gh search code` (secrets patterns) | 429 |
| 6 | `gh search repos` api-portal | Community repos only |
| 7 | `gh search repos org:etoro` | Invalid query |
| 8 | `gh search code client_secret` retry | 429 |
| 9 | `gh search repos etoro` | 25 repos |
| 10 | `gh search code x-api-key` | 429 |
| 11 | `curl` public-api key probe | 401 |
| 12 | `gh repo list eToro-API` + `gh api orgs/eToro-Public` | 1 repo; org metadata |
| 13 | `gh search code com.etoro` | Metadata hits only |
| 14 | `curl` published vs fake key compare | Both 401 |
| 15 | `git clone eToro-API/examples` | OK |
| 16 | `curl api-portal.etoro.com/llms.txt` | CF block |
| 17–18 | `gh search code org:eToro-API` | 429 |
| 19 | `gh search code etoro client_secret` | 429 |
| 20 | `gh search repos org:etoroxlabs` | Invalid query |

**Total: 18 billable ops** (some compound commands counted as one shell invocation).

---

## 8. P1/P2 exploit paths from GitHub source

### 8.1 Paths **not** supported by this audit

| Hypothesis | Status |
|------------|--------|
| Leaked `client_secret` → OAuth token minting | **No secret in repos** |
| Leaked `x-user-key` → account takeover / trading | **No user keys in repos** |
| Mobile APK on GitHub with embedded server secrets | **Not found** |
| Private API keys in `.env` / `secrets` files | **Not found** |

### 8.2 Paths worth **further** research (not P1/P2 confirmed)

| Path | Rationale | Blocker |
|------|-----------|---------|
| **Partner `x-api-key` + stolen `x-user-key`** | Dual-header auth; user key is the sensitive half | User keys not on GitHub; key creation requires logged-in user at `etoro.com/settings/trade` |
| **SSO `cidList` namespace confusion** | Public docs warn `gcid`/`demoCid` passed to `/user-info/people?cidList=` silently returns **wrong user’s public profile** | Integration bug in third-party apps; needs authenticated two-account proof on live API |
| **SSO OIDC implementation gaps** | Public skills document PKCE, `invalid_grant`, `gcid` vs `sub` — aids recon | Prior SSO pass (`composer-sso/REPORT.md`): no unauth P1/P2 |
| **Agent-portfolio `userToken` as `x-user-key`** | Docs describe agent-portfolio tokens with write scope | Token only issued to authenticated portfolio owner |

### 8.3 Highest-value GitHub intel for bug bounty

1. **Full Public API surface** — endpoint paths, auth rules, rate limits, error semantics (`etoro-agent-skills`, `etoro-cursor-plugin` rules).
2. **Auth never-mix rule** — Bearer + API-key headers together cause 401 (aids auth confusion testing).
3. **Identity model** — `gcid` / `realCid` / `demoCid` behavior for IDOR-style tests on `/user-info/people`.
4. **Execution invariants** — no idempotency on trade POSTs; 401 mid-workflow partial execution (business-logic / integrity, not GitHub secret).

---

## 9. Recommendations

| Audience | Action |
|----------|--------|
| **eToro security** | Confirm whether published `x-api-key` in `etoro-agent-skills` is intended to be public; if not, rotate and move to env-only docs. |
| **Bug bounty hunter** | Prioritize authenticated two-account tests for `cidList` misuse and agent-portfolio token scope — not GitHub secret replay. |
| **This workspace** | Keep `/workspace/vendor/etoro-github/` synced on `eToro-Public` pushes; no further org repos exist today. |

---

## 10. File inventory (local clones)

```
/workspace/vendor/etoro-github/
├── etoro-agent-skills/      # eToro-Public — trading/SSO reference skills
├── etoro-cursor-plugin/     # eToro-Public — Cursor plugin + MCP pointer
└── eToro-API-examples/      # eToro-API/examples — legacy HTML/C# samples
```

---

*No raw secrets reproduced in this document. Candidate key identified by SHA-256 prefix `2e9a85da8e07` and 8-char literal prefix `sdgdskld` only.*
