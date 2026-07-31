# Bugcrowd targets for ≥$500 — realistic picks (2026-07-31)

Goal: programs where **reproducible, undeniable** findings pay **$500+**, and where this cloud agent (or you free-tier) can actually prove impact.

Public listing scraped from `bugcrowd.com/engagements.json` (168 bug-bounty engagements).

---

## Best fit for *us* (proof-first)

| Priority | Program | Max listed | Why ≥$500 is realistic | How we prove |
|----------|---------|------------|------------------------|--------------|
| **1** | [Fireblocks MPC](https://bugcrowd.com/engagements/fireblocks-mbb-og2) | **$150k** | P3 Medium memory = **$3k–$15k** (your screenshot). **FB-MPC-001 already packaged** | GitHub `mpc-lib` + ASAN / unit tests — no login |
| **2** | [Fireblocks Web](https://bugcrowd.com/engagements/fireblocks-mbb-og) | **$12k** | Web/API; Medium often ≥$500 if in table | Needs auth + browser; harder in cloud |
| **3** | [Block Open Source](https://bugcrowd.com/engagements/blockopensource) | **$5k** | Explicit **open-source** scope — clone, build, PoC | GitHub audit + crash/security PoC |
| **4** | [Aiven](https://bugcrowd.com/engagements/aiven-mbb-og) | **$25k** | Open-source data platform (Kafka/PG/etc. managed) | Source + instance misconfig; careful of “upstream OSS unpaid” rules |
| **5** | [BitGo public / mobile](https://bugcrowd.com/engagements/bitgo-mbb-og-public) | up to **$4.5k+** | Crypto custody; MPC-adjacent | Mix of web + apps; auth heavy |
| **6** | [Magic Labs](https://bugcrowd.com/engagements/magiclabs-mbb-og) | **$3k** | Auth/wallet SDK — logic bugs pay if impact clear | Docs + client SDK source |
| **7** | [Orderly Network](https://bugcrowd.com/engagements/orderlynetwork-mbb-og2) | **$9k** | On-chain/trading infra; listed P3 bands include **$1k–$2k** | Chain + API PoCs |
| **8** | [Keeper Security](https://bugcrowd.com/engagements/keepersecurity) | **$10k** | Password manager — crypto/client bugs are “undeniable” if PoC | Client/extension analysis |
| **9** | [Cloudinary](https://bugcrowd.com/engagements/cloudinary) | **$4k** | Classic upload/SSRF/media pipeline bugs | Clear HTTP PoCs |
| **10** | [Bugcrowd’s own program](https://bugcrowd.com/engagements/bugcrowd) | **$10k** | Platform bugs; high bar but clear impact | Careful / no ToS abuse |

---

## High payout but *not* easy “undeniable” wins

| Program | Max | Reality check |
|---------|-----|----------------|
| OpenSea | $3M | Extremely hunted; NFT/web3 race |
| Okta | $75k | Elite auth hunters; hard P3 |
| Sophos / Cisco / AXIS OS | $40–80k | Product/firmware; long cycles |
| Binance / Blockchain.com / Bitpanda | $10–15k | Crowded crypto web |
| eToro | $15k | Avg ~$738; P3 $500–$1k; **needs dual login** |
| T-Mobile / SpaceX | $100k+ | Strict rules; not “quick Medium” |

---

## What actually clears “undeniable + ≥$500”

1. **ASAN/UBSan crash or memory corruption** on in-scope binary/lib (Fireblocks MPC style)  
2. **Authz IDOR** with two owned accounts + screenshots/HAR  
3. **Stored XSS → session theft** on authenticated surface  
4. **Crypto/auth logic bug** with unit-test PoC (wrong verify, key wipe, forge under stated bar)

Avoid: rate-limit, clickjacking, self-XSS, “missing header”, duplicates of open GitHub PRs.

---

## Recommended next move (money-first)

1. **Submit Fireblocks FB-MPC-001 now** (best ready ≥$500–$15k Medium candidate).  
2. Start **Block Open Source** + **Aiven** source hunts in parallel (clone → build → crash PoC).  
3. Keep eToro only if you paste **authenticated** eToro cURL from Comet.

I can pick **Block Open Source** or **Aiven** next and run the same find→reproduce→patch→report pipeline locally in your playbook (no vendor GitHub security issues).
