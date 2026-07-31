# VIE-002 — `/force_login` open redirect via `document.referrer`

**Target:** `https://mein.wien.gv.at/force_login` (and mirrored login JS on Standardportal login pages)  
**Proposed severity:** **P4** (open redirect)  
**Payout status:** **Excluded** — City of Vienna brief excludes **P4 and P5**. Do **not** submit for reward.  
**Status:** Client-side logic confirmed; kept only as chain material if it ever becomes part of a P1–P3 exploit path

## Reproduction

Login / force_login pages include:

```js
if (document.location.href.indexOf('/force_login') > -1) {
    document.location.href = (document.referrer.length)
        ? document.referrer
        : "https://mein.wien.gv.at";
}
```

Attacker hosts `https://evil.example/` with a link to `https://mein.wien.gv.at/force_login`.
Victim clicks → Mein Wien loads → JS navigates back to `evil.example`.

## Patch

```js
// Only allow same-site relative return paths
function safeReturn(ref) {
  try {
    var u = new URL(ref, window.location.origin);
    if (u.origin !== window.location.origin) return "https://mein.wien.gv.at";
    return u.pathname + u.search + u.hash;
  } catch (e) {
    return "https://mein.wien.gv.at";
  }
}

if (document.location.href.indexOf('/force_login') > -1) {
  document.location.href = document.referrer.length
    ? safeReturn(document.referrer)
    : "https://mein.wien.gv.at";
}
```

Prefer server-side allowlisted `redirect` / `returnUrl` instead of Referer.
