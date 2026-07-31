# Deep hunt notes — P1 / P2 / additional P3 (2026-07-30)

## Program bars (from Bugcrowd brief)

| Tier | Requirement |
|------|-------------|
| P1 Critical | Obtain key **or rogue signature** with &lt;1000 aborts / none |
| P2 High | Obtain key **or rogue signature** with &lt;1e9 failures/aborts |
| P3 Medium | Leak bits of private key **or cause memory corruption** |
| P4 Low | Narrower non-critical exposure |

## Crypto deep-dive (P1/P2 candidates)

| Candidate | Verdict |
|-----------|---------|
| Legacy MTA FS truncates `A` → forge range proof? | **Forgeability NOT established.** Full `A` still bound in Paillier/EC/RP verify equations; v≥11 uses extended seed. |
| Hardcoded `use_extended_seed=0` on signing DH proofs | Symmetric generate/verify; not a prover/verifier split. |
| `ry` mod wrong Paillier `n` when sizes differ | Negligible / retries on coprimality; no demonstrated leak. |
| FROST/BAM/EdDSA partial aggregation | Downstream checks + final verify reject bad partials. |

**P1/P2 result: none found.** No honest Critical/High path in this pass.

## Memory issues #55 / #56 (your question)

| PR | When raised | Merged? | Still broken on `main`? | Maps to |
|----|-------------|---------|-------------------------|---------|
| [#55](https://github.com/fireblocks/mpc-lib/pull/55) | 2026-06-15 | **Open, not merged** | **Yes** | **P3** (UBSan / alignment) — packaged as FB-MPC-004 with **broader** fix |
| [#56](https://github.com/fireblocks/mpc-lib/pull/56) | 2026-06-16 | **Open, not merged** | **Yes** (abort reproduced) | **P3/P4** — packaged as FB-MPC-003 with clearer fix |
| [#54](https://github.com/fireblocks/mpc-lib/pull/54)/[#57](https://github.com/fireblocks/mpc-lib/pull/57) | June 2026 | Open on GitHub; destructor wipe **already gone** on current `main` | Fixed in-tree by FROST-era cleanup | Was P3-class |

Submitting #55/#56 to Bugcrowd as “new” ≈ **duplicate / N-day**. They are real bugs and still unmerged, but **already public for weeks**.

### Quality vs open PRs

| Ours | vs open PR |
|------|------------|
| FB-MPC-003 | Same empty-guard; better comments / structure than #56 one-liner |
| FB-MPC-004 | Same `memcpy` helpers; covers **all** production serializers, not only RP+DF |

## Our unique finding

| ID | Tier | Notes |
|----|------|-------|
| **FB-MPC-001** | **P3 Medium** | Legacy MTA seed length mismatch → heap over-read when peer RP ≫ Paillier; ASAN proof. Not covered by #55/#56. |

## Bottom line for tuition / P1–P2 money

- **No P1 and no P2** after crypto + memory pass. Claiming Critical without a key/rogue-sig proof is dishonest and will not pay.
- **Ship FB-MPC-001** as the original Medium.
- Treat #55/#56 as **known-public P3/P4** — reproduce/fix locally (done); do not expect full bounty for duplicates.
- Next honest P2 hunt targets: CMP setup transcript binding, FROST nonce reuse / share aggregation edge cases, Paillier modulus validation gaps — only with a concrete exploit path.
