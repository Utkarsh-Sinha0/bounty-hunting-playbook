# VIE-001 — Mein Wien `/Verifizierung` Universal Links associated to Wiener Wohnen app

**Target:** `https://mein.wien.gv.at`  
**Program:** City of Vienna Managed Bug Bounty (Bugcrowd)  
**Research date:** 2026-07-31  
**Proposed severity:** **P2 candidate** (account-activation token interception on iOS)  
**Evidence grade:** L2 — misconfiguration + token-in-URL + unauthenticated activate API fully reproduced; **iOS Universal Link handoff not device-proven in this environment**

## Summary

`mein.wien.gv.at/.well-known/apple-app-site-association` claims the account-activation path `/Verifizierung` exclusively for the **Wiener Wohnen Mieterportal** iOS app (`78JUCXF9KC.at.wienerwohnen.mieterportal.app`), not for the official Stadt Wien apps.

The same path embeds email/account activation tokens from the query string into JavaScript and calls `GET /api/Account/ActivateAccount?token=…` with **no authentication and no CSRF requirement**.

If iOS opens activation emails via the Wiener Wohnen app instead of Safari / Stadt Wien, that app receives the secret activation token. That is a classic Universal Links / associated-domain failure mode for account takeover or verification abuse.

## Reproduction (no victim data)

### 1. AASA points `/Verifizierung` at Wiener Wohnen only

```bash
curl -sS https://mein.wien.gv.at/.well-known/apple-app-site-association
```

Observed (`aasa.json`, `Last-Modified: Wed, 29 Jul 2026 14:12:19 GMT`):

```json
{
  "applinks": {
    "apps": [],
    "details": [{
      "appID": "78JUCXF9KC.at.wienerwohnen.mieterportal.app",
      "paths": ["/Verifizierung"]
    }]
  }
}
```

Stadt Wien’s own App Store developer listing includes `Stadt Wien` (`id1014988960`) and other municipal apps — **none** of those bundle IDs appear in this AASA. Android `assetlinks.json` on the same host is **404**, so the risky association is iOS-specific.

### 2. Activation token is taken from the URL

```bash
curl -sS 'https://mein.wien.gv.at/Verifizierung?token=bb-research-invalid-token' \
  | rg -n "window.VERIFY|token :"
```

Observed:

```js
window.VERIFY = {
    token : 'bb-research-invalid-token',
    url:  "https://mein.wien.gv.at/login/?first=1&amp;type=Handy-Signatur"
}
```

Client code in `/dist/js/pages/login.js` calls:

`GET /api/Account/ActivateAccount?token=` + `VERIFY.token`

### 3. ActivateAccount is callable unauthenticated

```bash
curl -sS 'https://mein.wien.gv.at/api/Account/ActivateAccount?token=bb-research-invalid-token'
```

Observed (`activate_response.json`):

```json
{
  "message": "Account : Dieser Bestätigungslink ist ungültig oder wurde bereits verwendet. Versuchen Sie sich anzumelden.",
  "statusCode": 944
}
```

Same response **without cookies** and **without CSRF headers**. Invalid token → 944 proves the endpoint is live and token-gated only.

## Impact (why this can be P2)

1. Victim registers / changes email / receives Mein Wien activation mail containing  
   `https://mein.wien.gv.at/Verifizierung?token=<secret>`.
2. On an iPhone with Wiener Wohnen Mieterportal installed, iOS may hand the URL to that app (AASA claim).
3. The app (or a malicious/compromised build of it) can read `token` and call `ActivateAccount`, or prevent the victim’s browser from completing activation.
4. Resulting impact depends on product semantics: email verification takeover, registration completion by a third party, or denial of activation — all sensitive for a Stadt Wien Konto that stores applications, appointments, and payment methods.

**Not claimed as proven P1:** no end-to-end activation of a researcher-owned account via the WW app was performed here (no iOS device / no completed registration mailbox in this cloud agent).

## Out-of-scope / downgrade risks

- If Stadt Wien **intentionally** shares Mein Wien activation with Wiener Wohnen under a formal trust model **and** the WW app only opens a secure ASWebAuthenticationSession/Safari View to Mein Wien without logging the token, severity may drop.
- Still: claiming the path **only** for WW and **not** for official Stadt Wien apps is at least a high-risk misconfiguration and should be fixed.

## Patch / remediation

See `patch/`:

1. **Correct AASA** — remove third-party app claim for Mein Wien activation, or replace with official Stadt Wien app IDs only; prefer path exclusion for secrets.
2. **Stop putting secrets in query strings** — use one-time POST body / fragment / server session after signed email landing.
3. **Defense in depth** — bind activation tokens to user agent / require re-auth for sensitive linking; add Android `assetlinks.json` only for first-party apps.
4. **JS embedding** — tokens currently HTML-escaped but backslash is not JS-escaped (`token : 'test\',` → script SyntaxError). Use `JSON.stringify` for any future inline values.

## Related lower findings from same hunt

| ID | Issue | Likely VRT |
|----|-------|------------|
| VIE-002 | `/force_login` client redirect to `document.referrer` | P4 open redirect |
| VIE-003 | Backslash in `?token=` breaks VERIFY script | P5 / robustness |

## Program note

Third-party scope mirrors still list historical in-scope assets including `mein.wien.gv.at`. bbscope also shows a **Program Removed** event (2026-06-26). Confirm the live Bugcrowd brief/status before submission.