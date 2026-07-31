# City of Vienna — live hunt notes (2026-07-31)

## Verdict

**No submit-ready P1–P3.**  
Brief (researcher-confirmed): engagement **In progress**; only **P1–P3** pay. **P4/P5, CSRF, rate-limit, SPF/DKIM/DMARC, request smuggling** are excluded.

- **VIE-001** (AASA → Wiener Wohnen): **park** — WW is named as a City enterprise; likely intentional without device ATO PoC.
- **VIE-002** (force_login open redirect): **excluded as P4**.

Binding triage: `research/vienna/P1_P3_ONLY_TRIAGE.md`.

No authenticated two-account IDOR testing yet (need `@bugcrowdninja.com` accounts).

## Scope confidence

- Mein Wien + broker API + `*.wien.gv.at` + health/Azure/AS6720/apps confirmed in brief
- Out of scope: `www.wien.gv.at/advuew/*`, public event network `141.203.188.0/22`
- Rewards: P1 $2400–$3500 · P2 $750–$2400 · P3 $200–$750

## Surfaces exercised (manual, non-destructive)

| Surface | Result |
|---------|--------|
| `mein.wien.gv.at` login / bundle / page JS | Mapped Account/Transfer/Group APIs |
| `/api/Account/ActivateAccount` | Unauthenticated token activate endpoint live |
| AASA | WW Mieterportal claims `/Verifizierung` (likely intentional) |
| `/force_login` | Referer open redirect (**P4 excluded**) |
| `?token=` JS embed | Quotes HTML-escaped; `\` breaks script (**P5 excluded**) |
| Transfer/GetClientObjekt | Auth + CSRF required |
| IdaLogin | Returns ID Austria authorize URL + authId (expected) |
| `www.wien.gv.at/suche` XSS canaries | Reflections encoded / WAF on aggressive payloads |
| Common `*.wien.gv.at` subdomains | `stp-test`, `portal`, `assets` live; no dangling CNAME takeover in sample |
| `gesundheitsverbund.at` wp-json | 401; no version/RCE proof |
| SharePoint / M365 | Not tested (needs tenant canary) |
| Mobile binaries | Not downloaded |

## Highest-EV next steps (for a paying P1–P3)

1. Self-provision **two** accounts with `@bugcrowdninja.com` (brief: credentials self-provisioned).
2. Cross-account IDOR on payments, applications, appointments, `Transfer/*`, `Group/*`, broker API.
3. Auth bypass / ATO on Mein Wien + STP (phishing-resistant only if product bug, not social eng).
4. Single-request issues on AS6720 (recent P1 accepts) — no load/DDoS.
5. Stadt Wien iOS/Android apps for remote compromise.

## Index

- `research/vienna/P1_P3_ONLY_TRIAGE.md` — payout rules
- `findings/vienna/VIE-001-aasa-verifizierung/` — parked
- `findings/vienna/VIE-002-force-login-open-redirect.md` — excluded P4
