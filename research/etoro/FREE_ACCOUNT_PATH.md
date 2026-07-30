# Free-account path — how to hunt eToro without paying

You do **not** need a paid Bugcrowd plan, paid eToro Pro, or private GitHub access for the official public surfaces.

## What is already free

| Surface | How a free guy gets in |
|---------|------------------------|
| **Bugcrowd program** | Free Bugcrowd account → join [etoro-mbb-og](https://bugcrowd.com/engagements/etoro-mbb-og) (public engagement) |
| **eToro test accounts** | Sign up with `you@bugcrowdninja.com` (free Bugcrowd Ninja email) — required by the program |
| **Public GitHub** | Clone `eToro-Public/*`, `eToro-API/examples` — no auth |
| **Public web APIs** | Browser + Burp Community (free) against `*.etoro.com` with header `X-Bug-Bounty:<your_bc_username>` |
| **Mobile** | Free APK from Play Store / APKMirror → jadx (free) for client-side logic (server still needs your session) |

## Minimum setup (≈30 min, $0)

1. Create Bugcrowd account (free).
2. Note your Bugcrowd username.
3. Register **two** eToro accounts using `@bugcrowdninja.com` (Account A + Account B).
4. Install Burp Community or Caido free; add header on all traffic:
   ```
   X-Bug-Bounty: <your_bugcrowd_username>
   ```
5. Log into both accounts in two browser profiles; map authenticated APIs (Network tab → copy as curl).

## What free auth unlocks (this is where P1/P2 live)

With **two free Ninja accounts** you can test:

- **IDOR:** swap CID / gcid / resource IDs between A and B on messages, settings, withdrawals, KYC, API keys, billing
- **ATO chains:** XSS in authenticated `/app/*` → steal A’s session as B
- **OAuth:** register a free Builders/API portal app if eligible; test `redirect_uri` with your own client

Unauth + public GitHub alone will **not** get you P1/P2 on this program (we already proved that).

## What you cannot get for free

| Myth | Reality |
|------|---------|
| “Private eToro backend repo on GitHub for free” | **Doesn’t exist publicly.** Official public repos are skills/docs only |
| “Partner `x-api-key` from GitHub = account access” | Needs your **own** `x-user-key` from Settings → Trade |
| Cloud agent logs into your eToro for you | Needs **your** Ninja sessions / cookies (you paste or run locally) |

## Practical money path for a free account

1. Dual Ninja login locally (not cloud).
2. Hunt auth IDOR + DOM XSS→ATO (prior public ~$2.5k).
3. Submit on Bugcrowd only — never GitHub issues to eToro.
4. Expect mostly **P3/P4 ($100–$1k)**; P2 if you get real ATO/sensitive authz.

## Fireblocks side-note

`fireblocks/mpc-lib` is also **fully free** on GitHub — clone, build, ASAN — that path does **not** need an eToro account at all (separate program).
