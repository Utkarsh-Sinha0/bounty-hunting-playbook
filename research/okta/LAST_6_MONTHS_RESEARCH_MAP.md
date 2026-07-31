# Okta Bugcrowd — last 6 months research → P1/P2 triage

**Program:** [bugcrowd.com/engagements/okta](https://bugcrowd.com/engagements/okta)  
**Window:** ~Feb 2026 – Jul 31 2026 (plus late-2025 stack research still actively exploited/discussed)  
**Bar:** Impact-based. OIE P1 ≈ $10k–$75k; Workflows/PAM/ASA P1 ≈ $7k–$35k; Device Access P1 ≈ $10k–$75k. Limited **$500k** bonus for RCE/SQLi (announced Oct 2025).

## Verdict

**No proven new P1/P2 against Okta from public research alone.**

Last-6-months identity research is **highly relevant** to Okta’s in-scope stack (SAML/OIDC, FastPass, Workflows SSRF, multi-tenancy), but:

1. Okta-specific CVEs in the official trust feed for this window are sparse / older patches.
2. Ecosystem SAML bugs (authentik, Ruby-SAML, OneUptime, NetScaler) are **pattern transfer**, not Okta PoCs.
3. FastPass AiTM “bypasses” are mostly **policy / fallback / post-auth session** issues — often reduced severity or N/A under Okta’s MFA rules.
4. Recent researcher Workflows SSRF/sandbox reports were closed **Informational / N/A** without clear customer impact.

**You cannot claim P1/P2 until you have credentials + a working PoC on your `bugcrowd-pam-###` org.**

---

## Okta stack (what research must match)

| Product (in scope) | P1 range | Research-relevant attack classes |
|--------------------|----------|----------------------------------|
| **OIE** `bugcrowd-pam-###.oktapreview.com` | $10k–$75k | SAML/OIDC/XXE, Expression Language, cross-org, priv-esc, FastPass |
| **Workflows** | $7k–$35k | SSRF via Flo cards, cross-org Flo, sandbox escape → RCE |
| **Privileged Access (PAM)** | $7k–$35k | Secrets, resource/security admin, ASA agents |
| **Device Access / Desktop MFA** | $10k–$75k | Local agent pipes, password sync, Verify clients |
| **AtSpoke / Access Requests** | $5k–$25k | Team isolation, injection via Slack/Jira/SNOW, config-list bypass |
| **ASA / ScaleFT** | $7k–$35k | Client/agent compromise |
| **Okta Verify / Browser Plugin** | up to $75k | Auth bypass, plugin XSS/RCE, crypto on Personal |
| **Okta Personal** (`personal.trexcloud.com`) | (listed OOS in brief header but announced in-scope Aug 2025) | Admin/IdP dashboard access, crypto break, sharing |

**Out of scope / landmines:** Classic Engine (since May 2024), `*.okta.com` production, automated scanning, DoS (esp. Workflows), business-logic READ, session invalidation quirks, theoretical “could lead to” without PoC, AI-generated fluff reports.

---

## Research inventory → Okta mapping

### A. SAML / federation (highest pattern value for OIE)

| When | Finding | Source | Transfer to Okta? | P1/P2? |
|------|---------|--------|-------------------|--------|
| **Dec 2025** (BH Europe) | **“The Fragile Lock”** — dual XML parsers (REXML vs Nokogiri / xmlseclibs) → signature validation sees different doc than assertion logic; attribute pollution, namespace confusion, void canonicalization. CVE-2025-66568/66567 | PortSwigger / WorkOS summary | **Hunt direction only.** Okta focus areas explicitly list SAML + XXE. If Okta’s IdP/SP path uses dual parsers or separates verify vs extract → auth bypass = **P1**. Not publicly shown against Okta. | **Not proven** |
| **Feb–Apr 2026** | SAML assertion injection when only assertion *or* response signature verified (authentik CVE-2026-25922 / CVE-2026-47201 XSW; OneUptime CVE-2026-34840) | Multiple OSS IdPs | Same class: prepend unsigned assertion, verify first signature, extract wrong identity. Test Okta as **SP** for inbound IdP and as **IdP** for apps. | **Not proven** |
| **Mar 2026** | Citrix NetScaler SAML IdP memory leak CVE-2026-3055 (actively exploited) | WatchTowr / CISA KEV | Wrong product. Pattern: SAML edge IdPs leak sessions. Okta cloud IdP ≠ NetScaler. | **N/A** |
| **Mar 2026** | XXE in esaml (Erlang) CVE-2026-28809 | OSV | Pattern for XXE-before-sig-verify. Okta lists XXE as focus; needs live XML endpoints (SAML metadata/ACS, agents). | **Hunt** |

**Actionable tests (need org):**

1. As SP: federate a malicious/test IdP → try XSW / dual-assertion / response-vs-assertion signing gaps.
2. As IdP: craft AuthnRequest / AssertionConsumer quirks; probe XXE in metadata upload and SAML responses Okta emits/consumes.
3. Diff signed element vs consumed NameID/email claims (classic XSW checklist).

### B. FastPass / Okta Verify / phishing resistance

| When | Finding | Source | Transfer / severity under Okta rules |
|------|---------|--------|--------------------------------------|
| **2025–2026** | FastPass phishing resistance depends on **loopback Origin check**; fallback to **custom URI scheme** drops Origin → AiTM possible if phishing-resistant policy **not enforced** | Obsidian Security; Persistent Security | Often **customer misconfig**. Okta requires you enforce MFA policies yourself. Policy-not-set ≠ product P1. If you can force Custom URI **despite** phishing-resistant policy on preview → **P1/P2**. |
| **2025** | **OktaTerrify / OktaInk** — needs local access to victim TPM/Verify DB to mint FastPass tokens | Red-team writeups | Brief: local-only / already-compromised device often **not Critical**. Persistence after foothold ≠ initial-access P1. |
| **Ongoing** | Session cookie theft post-MFA; FastPass ≠ DPoP by default | Blade Intel | Session theft after legit MFA is known; Okta may rate as config / expected. Need **server-side MFA bypass** for Full MFA Bypass focus. |
| **Nov 2024** (edge of window) | CVE-2024-9191 Desktop MFA Windows pipe password disclosure | Okta advisory | Patched 5.3.3+. Re-test **newer** Verify for similar named-pipe / IPC issues on Device Access → possible P2/P1 if still present. |
| **Oct 2024** | CVE-2024-10327 iOS push ContextExtension both buttons succeed | Okta advisory | Patched. Look for push/decision logic bugs on current Verify iOS/Android. |

**Actionable tests:**

1. With phishing-resistant policy **on**: try to coerce Custom URI / disable loopback; document Origin handling.
2. Device Access MFA Win/mac: IPC, password sync, agent update paths (RCE bonus if update RCE).
3. Fastpass enrollment / Bluetooth bootstrap abuse → bind attacker device (Obsidian enrollment angle).

### C. Workflows (SSRF / sandbox / cross-org)

| When | Finding | Outcome for hunters |
|------|---------|---------------------|
| **Feb 2026** | Blind SSRF + DNS exfil via Raw Request / File Download cards (Genki) | Closed **Informational (P5)** — outbound to attacker domain alone ≠ payout |
| **Feb 2026** | Prototype pollution / AST sandbox escape / V8 heap leak in Formula card (Genki) | **N/A / Not Reproducible** |
| Release notes | Okta shipped SSRF security fixes in Workflows | Confirms SSRF is real product risk; need **impact**: cloud metadata, internal admin APIs, **cross-org** data, RCE |

**What still pays (per brief focus):**

- SSRF that reaches **internal** services or other tenants’ Workflows
- Flo actions / secrets **across orgs**
- Escape sandbox → **RCE** (eligible for **$500k bonus**)
- Bypass 5-active-flow limit with security impact
- Role/permission bypass (Workflows roles doc)

Do **not** automate / DoS Workflows — instant ban.

### D. Multi-tenancy / cross-org / AtSpoke

| Theme | Notes |
|-------|-------|
| Cross-tenant impersonation | 2024-class incidents were support/HAR/session process issues; still hunt IDOR across `bugcrowd-pam-A` vs `bugcrowd-pam-B` with **2 credential sets** |
| AtSpoke team matrix | Brief gives explicit allow/deny table — deviations (view/edit private request on another team) = clear P2/P1 |
| Config lists / request-type isolation | Focus areas in brief |

### E. Okta Personal / crypto

| Finding | Payout likelihood |
|---------|-------------------|
| OTP email rate-limit missing on `personal.trexcloud.com` (public writeup) | Usually **P4/OOS** (rate limit / spam) |
| Break Personal crypto → decrypt user vault | Explicit focus → **P1** if proven |
| Reach Personal Admin / IdP dashboard | **Stop and report** (P1-class) |

### F. Official Okta advisories (trust.okta.com)

Latest listed advisories cluster in **2024** (Verify Windows/iOS, Classic policy bypass, AD/LDAP bcrypt cache, browser plugin XSS). Classic bypass is **out of scope**. Use as regression checklist on **current** OIE/Verify/agents, not as submit-as-new.

---

## What does *not* become Okta P1/P2 from research alone

| Claim | Why it fails Okta criteria |
|-------|----------------------------|
| “FastPass can be AiTM’d if policy weak” | Misconfig / expected; not Full MFA Bypass |
| “Blind SSRF DNS callback from Workflows” | Already Informational |
| “SAML XSW works on authentik” | Different product |
| “Theoretical Expression Language RCE” | Must have complete PoC; theoretical OOS |
| Classic Engine policy bypass | Classic **out of scope** |
| Rate-limit / enumeration / missing headers | Explicitly OOS |

---

## Highest-EV hunt plan (ordered)

1. **Claim credentials** (“Get Credentials”) → rename emails → add 2 Super Admins → enforce MFA per brief.
2. **Two-org isolation:** org A vs org B IDOR on Admin APIs, Workflows stash, PAM secrets, AtSpoke private requests.
3. **SAML Fragile Lock patterns:** dual-parser / XSW / assertion-order on inbound IdP and outbound apps.
4. **Workflows:** Raw Request / File Download → *internal* impact or cross-org; Formula sandbox → RCE for bonus.
5. **FastPass:** only with phishing-resistant **enforced**; prove policy bypass or enrollment bind.
6. **Device Access / Verify agents:** IPC, update, Desktop MFA (RCE/SQLi = bonus).
7. **Okta Personal:** crypto / admin dashboard only; stop on dashboard access.

---

## Bottom line

| Question | Answer |
|----------|--------|
| Does last-6-months research **prove** Okta P1/P2 today? | **No** |
| Does it create a **credible P1/P2 hunt map**? | **Yes** — SAML XSW/Fragile Lock, Workflows SSRF→internal/RCE, cross-org, FastPass policy-enforced bypass |
| Best payout levers | OIE/Device Access P1 ($10–75k); Workflows RCE ($500k bonus); cross-org / SAML auth bypass |
| Blocker | Credentials not assigned yet — claim before testing |

Full citations live in this file; do not submit AI-only reports (Okta rejects them).
