# Deep hunt notes — P2 / additional P3 (2026-07-30)

## Program bars (from Bugcrowd brief)

| Tier | Requirement |
|------|-------------|
| P2 High | Obtain key **or rogue signature** with &lt; 1e9 failures/aborts |
| P3 Medium | Leak bits of private key **or cause memory corruption** |

## Crypto deep-dive (P2 candidates)

| Candidate | Verdict |
|-----------|---------|
| Legacy MTA FS truncates `A` → forge range proof? | **Forgeability NOT established.** Full `A` still bound in Paillier/EC/RP verify equations; v≥11 uses extended seed. |
| Hardcoded `use_extended_seed=0` on signing DH proofs | Symmetric generate/verify; not a prover/verifier split. |
| `ry` mod wrong Paillier `n` when sizes differ | Negligible / retries on coprimality; no demonstrated leak. |
| FROST/BAM/EdDSA partial aggregation | Downstream checks + final verify reject bad partials. |

**P2 result: none found.**

## Memory deep-dive (extra P3 candidates)

### Still in tree, but already public on GitHub

| Issue | Location | Evidence | Public prior art |
|-------|----------|----------|------------------|
| Empty `container_cleaner` UB | `include/utils/string_utils.h:18` `OPENSSL_cleanse(&_secret[0], …)` | Aborts under `_GLIBCXX_ASSERTIONS` | Open PR [#56](https://github.com/fireblocks/mpc-lib/pull/56) |
| Misaligned `*(uint32_t*)` after BN payload | `ring_pedersen.c`, `damgard_fujisaki.c` | UBSan on aarch64 (PR logs); DF deserialize attacker-reachable | Open PR [#55](https://github.com/fireblocks/mpc-lib/pull/55) |
| `~ecdsa_preprocessing_data` cleanses over live maps | Was `OPENSSL_cleanse(this, sizeof…)` | Heap leak + UB | Open PRs [#54](https://github.com/fireblocks/mpc-lib/pull/54)/[#57](https://github.com/fireblocks/mpc-lib/pull/57) — **already removed in current `main` snapshot** |

Submitting #55/#56 as “new” Bugcrowd reports is **high duplicate / N-day risk** (public since mid-June 2026, &gt;14 days).

### Our unique finding

| ID | Tier | Notes |
|----|------|-------|
| **FB-MPC-001** | **P3 Medium** | Legacy MTA seed length mismatch → heap over-read when peer RP ≫ Paillier; ASAN proof. Not covered by the open PRs above. |

## What professors may be referring to

The open PRs (#54–#57) are exactly the class of “cryptography-adjacent memory issues” (UB, misalignment, destructor wipe). Those are real, but **already disclosed publicly**. They do not upgrade to P2 (no key/rogue signature).

## Bottom line

- **No P2** after deeper crypto + memory pass.
- **More P3-class bugs exist** but are **already on GitHub** → do not re-submit as original.
- **Ship FB-MPC-001** as the original Medium candidate with ASAN.
