# CrowdStream → P1/P2 hunt map (City of Vienna)

**Source:** Bugcrowd CrowdStream accepts ~Jul 7–29 2026 (researcher-pasted)  
**Rule:** only **P1–P3** pay; ignore P4/P5/CSRF/rate-limit/mail-auth/smuggling.

## What paid recently

| Target | Priority | Sample rewards | Volume signal |
|--------|----------|----------------|---------------|
| `*.wien.gv.at` | **P1** (dominant) | $2400–$3500 | Many accepts by **soeckly** in ~2 weeks |
| `AS6720 2/2` (`217.149.224.0/20`) | **P1** | $2400–$3000 | Same researcher, same week |
| `www.wien.gv.at` | P1 / P3 | $2400 / unlisted | Fewer |
| `*.wien.at` | P1 | $2400 | At least one |
| `*.gesundheitsverbund.at` | P2 / P3 | $350+ | Health stack |
| FTAPI `secumails.gesundheitsverbund.at` | P3 | — | Secure mail |

**Inference (not proof of bug class):** a single researcher landing **many P1s** on both the **wildcard** and the **ASN** in days usually means infrastructure-class issues (exposed service family, takeover cluster, auth bypass on edge/gateway, misconfigured management plane) — **not** one-off Mein Wien business-logic bugs.

Mein Wien / broker have known-issue counts but **do not appear** in this CrowdStream payout sample → lower EV right now vs `*.wien.gv.at` + AS6720.

## Ordered hunt plan (payout EV)

1. **AS6720 edge / management surfaces** (single-request only; no load/DDoS)
   - Hosts already resolving into `217.149.224.0/20` / `141.203.0.0/16`
   - Look for: unauthenticated admin consoles, API gateways, OpenShift/K8s consoles, monitoring, file shares, forgotten `*-test` / `appdev` panels with weak auth
   - Recent P1s here are the clearest money signal

2. **`*.wien.gv.at` inventory → dangling / takeover / panel**
   - Expand passive DNS/CT beyond Hackertarget’s 50-row cap
   - Prioritize: `*test*`, `*dev*`, `*uat*`, `*admin*`, `*vpn*`, `*git*`, `*monitor*`, `*console*`, `*api*`
   - Confirm takeover only with claim proof (no squatting outside program rules)

3. **`*.gesundheitsverbund.at` app security (P2/P3 proven payable)**
   - Live apps fingerprinted this hunt:
     - `3dhisto…/SlideCenter` (digital pathology login)
     - `arex…/ArexWeb` (ASP.NET + SignalR; version `3.9228.0.0` via unauth `Signal/VersionInfo`)
     - `secumails…` FTAPI (already paid P3 to someone — hunt adjacent, not dup noise)
   - **Stop immediately** on any real patient/employee PII; use only researcher-owned accounts / synthetic data

4. **`www.wien.gv.at` / `*.wien.at`**
   - High-impact XSS, auth issues, sensitive exposure — not open redirects (P4 excluded)

5. **Mein Wien** only after two `@bugcrowdninja.com` accounts for IDOR/ATO (still valid P1/P2 path, just quieter in CrowdStream)

## Passive fingerprinted this session (leads, not bugs)

| Host | Notes | P1–P3 angle |
|------|-------|-------------|
| `appdev.wien.gv.at` / `app.wien.gv.at` | `217.149.229.155`, gateway **403** | IP-allowlisted app host — probe from allowed paths / sibling vhosts only |
| `stp-test.wien.gv.at` | Test Standardportal on ASN | Auth boundary vs prod; config leaks |
| `portal.wien.gv.at` | Production STP sibling | Same |
| `3dhisto.gesundheitsverbund.at` | SlideCenter login | Auth bypass / IDOR on slides → P1/P2 if proven **without** touching real patient data |
| `arex.gesundheitsverbund.at` | AREX 3.9228.0.0; jQuery 1.10.2; SignalR | Unauth version = P5; hunt authZ / IDOR instead |
| `wibi.wien.gv.at` | Named target; A=`89.145.162.200` (off common AS6720 web farm) | App/API issues |

## What **not** to waste time on (exclusions / low EV)

- Open redirects, CSRF, missing rate limits, SPF/DKIM/DMARC, request smuggling
- Version banners alone (AREX `VersionInfo`)
- Mein Wien AASA → Wiener Wohnen without device ATO (WW is City enterprise)
- Mass port scanning / load testing of AS6720

## Researcher workflow to match soeckly-tier P1s

1. Build full host list (CT + passive DNS + ASN-owned reverse where ethical/single-request).
2. For each live host: one GET `/` + tech fingerprint; queue only **auth-required apps**, **dev/test**, **management**, **takeover candidates**.
3. On ASN: prefer hosts that are **not** the public CMS — those are where P1s cluster.
4. Health apps: treat as high impact but **minimal evidence** discipline.
5. Submit only with full PoC and clear VRT P1–P3 impact.

## Status

CrowdStream **redirects the hunt** to `*.wien.gv.at` + **AS6720** + health apps.  
**Still no submit-ready P1/P2 packaged in this environment** — needs deeper host inventory + authenticated/device testing for the classes that actually paid.
