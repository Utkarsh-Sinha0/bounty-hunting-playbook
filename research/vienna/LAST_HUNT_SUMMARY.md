# City of Vienna — live hunt notes (2026-07-31)

## Verdict

**No fully proven P1.**  
**Strongest issue found: VIE-001 (AASA `/Verifizierung` → Wiener Wohnen) — P2 candidate**, reproduced at the configuration + token API layer; iOS handoff still needs a device PoC before confident Bugcrowd P2 payout.

No authenticated two-account IDOR testing was possible (no Stadt Wien Konto / second mailbox in this environment).

## Scope confidence

- Official page still points researchers to Bugcrowd: https://digitales.wien.gv.at/bugbounty/
- Bugcrowd engagement page is login-gated from this environment
- bbscope shows historical scope including `mein.wien.gv.at` **and** a **Program Removed** event on 2026-06-26 — verify brief before submit

## Surfaces exercised (manual, non-destructive)

| Surface | Result |
|---------|--------|
| `mein.wien.gv.at` login / bundle / page JS | Mapped Account/Transfer/Group APIs |
| `/api/Account/ActivateAccount` | Unauthenticated token activate endpoint live |
| AASA | Third-party WW app claims `/Verifizierung` |
| `/force_login` | Referer open redirect (P4) |
| `?token=` JS embed | Quotes HTML-escaped; `\` breaks script (P5) |
| Transfer/GetClientObjekt | Auth + CSRF required (918/401) |
| IdaLogin | Returns ID Austria authorize URL + authId (expected) |
| `gesundheitsverbund.at` wp-json | 401; no version/RCE proof |
| SharePoint / M365 | Not tested (needs tenant canary) |
| Mobile binaries | Not downloaded |

## Highest-EV next steps (researcher with accounts + iPhone)

1. Register two Mein Wien accounts; complete email verification while capturing links.
2. Install Wiener Wohnen Mieterportal; open activation link from Mail — confirm which app handles it and whether token is logged/exfiltrated.
3. Cross-account IDOR on `Transfer/*`, payments, appointments, `Group/AcceptInvite?benutzerId=`.
4. Fast-follow password-reset tokens on `/Zugangsdaten-vergessen?token=` (not in AASA today).

## Index

- `findings/vienna/VIE-001-aasa-verifizierung/` — P2 candidate + patch
- `findings/vienna/VIE-002-force-login-open-redirect.md` — P4 + patch
- `research/vienna/LAST_HUNT_SUMMARY.md` — this file
