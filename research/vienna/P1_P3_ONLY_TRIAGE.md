# City of Vienna — payout-eligible triage (P1–P3 only)

**Brief confirmed by researcher (2026-07-31):** engagement **In progress** (started 2025-01-16).  
**Rewards:** P1 $2400–$3500 · P2 $750–$2400 · P3 $200–$750  
**Uses Bugcrowd VRT**, with program-specific exclusions.

## Hard exclusions (do not submit for reward)

| Exclusion | Impact on our hunt |
|-----------|-------------------|
| **P4 vulnerabilities** | Open redirects, low misconfig, weak CSRF-adjacent noise — **dead** |
| **P5 vulnerabilities** | Info disclosure / robustness / script SyntaxError — **dead** |
| **CSRF** | Entire class excluded (even if VRT would rate higher) |
| **No rate limiting** | Enumeration/bruteforce via missing limits — **dead** |
| **DMARC / DKIM / SPF** | Dead |
| **Request smuggling** | Temporarily excluded while central fix lands |

Also: phishing, DDoS (single-request DoS still allowed), leaked/purchased creds, out-of-scope hosts/IPs, support forms, other users’ data.

## Reclassification of prior findings

| ID | Prior call | Under this brief | Action |
|----|------------|------------------|--------|
| **VIE-001** AASA `/Verifizierung` → Wiener Wohnen | P2 candidate | **Likely N/A or non-paying** without proven hostile token theft. Brief explicitly names **Wiener Wohnen** as a City independent enterprise — associated-domain claim may be **intentional**. Without iOS PoC showing non-consensual interception / ATO, do **not** submit as P2. | Park; only reopen with device ATO chain |
| **VIE-002** `/force_login` referer redirect | P4 open redirect | **Excluded (P4)** | Do not submit |
| Token `\` script break | P5 | **Excluded (P5)** | Do not submit |

## What still pays (hunt focus)

| Class | Typical priority if proven | Needs |
|-------|---------------------------|-------|
| Auth bypass / ATO on Mein Wien, STP, apps | P1–P2 | `@bugcrowdninja.com` accounts (self-provision) |
| Cross-user IDOR (applications, payments, appointments, groups) | P1–P2 (impact-dependent) | Two researcher accounts |
| Stored XSS / high-impact reflected XSS | P2–P3 | PoC without breaking ToS |
| RCE / SQLi / SSRF→internal impact | P1–P2 | Non-destructive PoC |
| Subdomain takeover (basic, critical impact) | P1–P3 | Claim proof |
| Sensitive data exposure (PII of **your** test data only) | P2–P3 | Minimal evidence |
| Mobile app remote compromise (Stadt Wien apps) | P1–P2 | Device + app |

Recent CrowdStream (Jul 2026): multiple **P1** accepts on `*.wien.gv.at` and **AS6720** ($2400–$3000) — infra/network single-request issues remain valuable.

## Current live-hunt status

**No submit-ready P1–P3 yet** in this environment.

Blockers:

1. No `@bugcrowdninja.com` mailbox / Mein Wien accounts for IDOR/ATO.
2. No iOS/Android device for Stadt Wien app P1–P2.
3. Public unauth surfaces checked so far (search XSS canaries, broker swagger, common subdomains, ActivateAccount) did not yield a clean P1–P3 PoC.

## Immediate workflow for a paying report

1. Create **two** Stadt Wien / Mein Wien accounts with `@bugcrowdninja.com`.
2. Enforce normal MFA if offered; keep sessions for A↔B object swaps.
3. Prioritize: payments, applications, appointments, `Transfer/*`, `Group/*`, ID Austria linking, broker API.
4. Only submit issues with **reproducible impact** that clear P3+ under VRT **and** survive the exclusion list.
5. Skip anything that is “only” open redirect, CSRF, rate limit, or mail-auth.

## Artifacts

- Prior research retained under `findings/vienna/` for context — **not** submission-ready under P1–P3-only rules.
- This file is the binding triage for payout hunting.
