# Last 6 months research → Fireblocks `mpc-lib` (P1/P2 triage)

**Window:** ~Feb 2026 – Jul 31 2026  
**Target:** `fireblocks/mpc-lib` (CMP/CGGMP-style ECDSA, MtA+Paillier+Ring-Pedersen, offline/presign, HD BIP32, FROST 2-of-2, BAM ECDSA, EdDSA)  
**Bugcrowd bar:** P1 = key / rogue sig with &lt;1000 aborts; P2 = same with &lt;1e9 failures

## Verdict

**No new P1 or P2 arises from last-6-months research when mapped onto current `mpc-lib`.**

The highest-severity *protocol* issues in this window either (a) hit a different protocol family (DKLs / OpenVM pairings / Lindell17 DKG), (b) were disclosed **by Fireblocks researchers** and are already present in their verifier, or (c) are already mitigated in-tree (`MPC_RAND_R_VERSION` re-randomizes `R`).

---

## Fireblocks stack (what research must match)

| Component | In repo? | Notes |
|-----------|----------|-------|
| MPC CMP / CGGMP-style ECDSA | **Yes** | README cites ePrint 2020/492; Paillier MtA + ZK |
| Offline / presigning | **Yes** | `cmp_ecdsa_offline_signing_service` |
| Additive HD derivation | **Yes** | BIP32-style `derivation_key_delta` / chaincode |
| Paillier-Blum modulus ZK | **Yes** | `paillier_verify_paillier_blum_zkp` |
| Large-factors / Ring-Pedersen ZK | **Yes** | setup + MtA range proofs |
| FROST Schnorr | **Yes** | client/server **2-of-2**, not general t-of-n |
| BAM ECDSA (asymmetric 2P) | **Yes** | |
| DKLs / VOLE / OT-based | **No** | |
| Pairing / KZG / Groth16 | **No** | |
| Lindell17 DKG 3x'+x'' | **No** | |

---

## Research inventory (last ~6 months, stack-relevant)

### A. Critical / high — protocol or implementation bugs

| When | Source | Finding | Transfer to Fireblocks? | P1/P2? |
|------|--------|---------|-------------------------|--------|
| **Nov 2025** (patched; still active thru 2026) | [CVE-2025-66016](https://osv.dev/vulnerability/CVE-2025-66016) / [DFNS writeup](https://dfns.co/article/cggmp21-vulnerabilities-patched-and-explained/) / RUSTSEC-2025-0129 | **Missing check in Paillier-Blum ZK** during aux keygen → single malicious signer can reconstruct full private key. Disclosed **by Fireblocks (Arik Galansky)**. Patch in `paillier-zk` 0.4.3 is `gcd(N, w) == 1`. | **Already present** in `mpc-lib`: `is_coprime_fast(proof.w, pub->n)` in `paillier_verify_paillier_blum_zkp` (~L1526). Fireblocks found this because *their* verifier had the check and paper/CGGMP21 text did not. | **No** — not vulnerable |
| **Nov 2025** (same DFNS notice) | Groth–Shoup class / DFNS Vuln 2 | **Presignatures + raw signing** → signature forgery by choosing digest as function of public `R`. Related: **presign + HD** → ~85-bit security reduction (not full key theft). | Fireblocks has offline/presign + HD, **but** `MPC_RAND_R_VERSION = 8` re-randomizes: `R' = R · H(R, derived_pk, m)` before projecting `r` / computing `s`. Current `MPC_PROTOCOL_VERSION` ≥ 8. | **No** — mitigated for current protocol versions; not &lt;1e9 work even in theoretical HD+presign cube-root variant |
| **May–Jul 2026** | [ePrint 2026/929](https://eprint.iacr.org/2026/929) Segev | DKLs23 **not statistically UC-secure** (split-view on nonce `R`); still **computationally** secure; fix = nonce-consistency check | Wrong protocol (VOLE/DKLs, not CMP). Offline path already compares peer `r`; online finalize verifies ECDSA. | **No** |
| **Jul 2026** | [zkSecurity bron-crypto](https://blog.zksecurity.xyz/posts/bron-bugs/) | Lindell17 DKG swapped operands; inverted `IsOnCurve`; Poseidon `hash.Hash`; `IsZero`→`IsOne` | No Lindell17 DKG; MtA shape `Enc(k)^x·Enc(β)` correct; curve checks not inverted | **No** |
| **Jul 2026** | [zkSecurity OpenVM / CVE-2026-46669](https://blog.zksecurity.xyz/posts/openvm-bugs/) | Pairing check missing Fp6 subfield constraint → forge pairings | No pairing code in mpc-lib | **No** |
| **Jul 2026** | [zkSecurity CIRCL](https://blog.zksecurity.xyz/posts/circl-bugs/) | float64 RSA poly, int64 Lagrange, BLS distinctness, HPKE switch, CP-ABE, DLEQ | Different primitives; Fireblocks Lagrange uses BIGNUM | **No** |

### B. Theory / design papers (do not yield PoC P1/P2 on this repo)

| When | Source | Relevance | P1/P2? |
|------|--------|-----------|--------|
| May–Jun 2025 | [ePrint 2025/1001](https://eprint.iacr.org/2025/1001), [2025/1061](https://eprint.iacr.org/2025/1061); NIST MPTS Jan 2026 | FROST **adaptive** security limits (full t−1 needs LDVR; half adaptive OK under AOMDL) | Fireblocks FROST is **2-of-2**; adaptive t−1=1 is the static threat model already assumed. Not a concrete forge against honest co-signer. **No** |
| Sep 2025 / CCS | [ePrint 2025/1696](https://eprint.iacr.org/2025/1696) Threshold ECDSA in two rounds | Presign security loss (Groth–Shoup); re-randomization as fix | Already addressed via `MPC_RAND_R_VERSION`. **No** |
| Jul 2026 | [Trout++ 2026/1455](https://eprint.iacr.org/2026/1455) | New protocol, not an attack on CMP | **No** |
| 2026 | ARES/ARES+, HW-friendly CL-MtA, DKLs VOLE param papers | New constructions / OT-VOLE params | **No** |
| May–Jun 2026 | [mpcsec.org](https://mpcsec.org/) pitfall taxonomy | Checklist (input validation, context binding, etc.) | Already used in prior hunt → P3/P4 only (FB-MPC-001/006/007). **No P1/P2** |

### C. Older but still-cited stack attacks (outside 6 months; re-checked)

| CVE / paper | Status in Fireblocks |
|-------------|----------------------|
| CVE-2023-33241 GG18/GG20 small Paillier factors (Fireblocks BitForge) | CMP uses Blum + large-factor ZK; not GG18 |
| Alpha-Rays / small Paillier N in MtA ZK | Size / Blum / large-factor proofs present |
| Verichains TSShock c-split / α-shuffle | Targets flawed MtA DL proofs; CGGMP-style range proofs + extended MTA path |

---

## Deep check: CVE-2025-66016 vs `mpc-lib`

**Missing check in vulnerable libs:** `gcd(N, w) == 1` on Paillier-Blum commitment `w` before accepting the proof (`paillier-zk` 0.4.1 → 0.4.3).

**Fireblocks verifier (already present):**

```1526:1530:vendor/mpc-lib/src/common/crypto/paillier/paillier_zkp.c
    if (is_coprime_fast(proof.w, pub->n, ctx) != 1)
    {
        ret = PAILLIER_ERROR_INVALID_PROOF;
        goto cleanup;
    }
```

Also rejects even `N`, `N % 4 != 1`, prime `N`, non-coprime challenges, and checks `z^n ≡ y (mod N)` plus fourth-root relations. Setup calls this via `cmp_setup_service::verify_setup_proofs`.

**Implication:** Submitting “missing Blum gcd check” against Fireblocks MPC would be **incorrect / N-day on other vendors**, not a Fireblocks P1.

---

## Deep check: Presign + HD / raw signing (DFNS Vuln 2 / Groth–Shoup)

Offline finalize when `protocol_version >= MPC_RAND_R_VERSION` (8):

```357:373:vendor/mpc-lib/src/common/cosigner/cmp_ecdsa_offline_signing_service.cpp
        if (protocol_version >= MPC_RAND_R_VERSION)
        {
            // ...
            SHA256_Update(&hash_ctx, preprocessed_data.R.data, ...);
            SHA256_Update(&hash_ctx, derived_public_key, ...);
            SHA256_Update(&hash_ctx, data.blocks[i].data.data(), ...);
            SHA256_Final(hram, &hash_ctx);
            // R' = R * hram ; later s adjusted by hram^{-1}
```

This is the standard **re-randomization** mitigation. Current protocol version constant is `MPC_BAM_ECDSA = 13` (≥ 8).

**Implication:** No clean P1/P2 from “raw digest + public R” on current protocol path. Legacy clients on version &lt; 8 are out of scope for “current main” unless Bugcrowd explicitly includes downgrade/compat.

---

## Residual open questions (not proven P1/P2)

These are honest follow-ups if continuing the hunt — **none are currently evidenced as P1/P2**:

1. **CGGMP24 “extra” checks** beyond the Blum `gcd(N,w)` fix — DFNS warns CGGMP21 patches alone miss later paper clarifications. Fireblocks’ proofs are home-grown C/OpenSSL (not Lockness); would need a line-by-line CGGMP24 Figure checklist vs `paillier_zkp.c` / `range_proofs.c`. Speculative until a failing check is shown.
2. **Legacy protocol versions** (&lt; `MPC_RAND_R_VERSION` or &lt; `MPC_EXTENDED_MTA`) if still reachable in production — product/deployment question, not a pure open-source crypto PoC.
3. **FROST peer D/E validation** — already packaged as FB-MPC-006 (P3/P4), not rogue-sig.
4. **FB-MPC-001** legacy MTA seed length — still best **original P3**.

---

## Bottom line

| Question | Answer |
|----------|--------|
| Any last-6-months research → **new Fireblocks P1**? | **No** |
| Any → **new Fireblocks P2**? | **No** |
| Hottest near-miss | CVE-2025-66016 — **already fixed / disclosed by Fireblocks** |
| Hottest theoretical near-miss | Presign+HD — **mitigated by `MPC_RAND_R_VERSION`** |
| Still-valid bounty path | **FB-MPC-001** (P3) and hygiene P3/P4 only |

Do **not** claim P1/P2 from AI crypto posts or DKLs/FROST adaptive papers without a concrete key/rogue-sig PoC against honest co-signer under Bugcrowd abort bounds.
