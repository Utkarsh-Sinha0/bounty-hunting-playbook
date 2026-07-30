# Deep hunt team report — P1/P2/P3 (2026-07-30)

## Method

Parallel crypto subagents + cross-check against:
- Zion Boggan Fireblocks mpc-lib notebook (public, Apr 2026)
- zkSecurity / Codex dual-agent bron-crypto writeup (pattern transfer only — different codebase)
- Trail of Bits threshold DKG coefficient-length attacks
- Open GitHub PRs #54–#57

## P1 Critical / P2 High — verdict

| Claim | Result |
|-------|--------|
| **P1 key / rogue sig (&lt;1000 aborts)** | **Not found** |
| **P2 key / rogue sig (&lt;1e9 aborts)** | **Not found** |
| Zion “8-bit batch gamma = P2 @ 1/256” | **Mis-model.** Code uses `BATCH_STATISTICAL_SECURITY=5` independent 8-bit gammas ⇒ **~2⁻⁴⁰**, matching RP’s intentional 40-bit batch. Not P2 under program bar. |
| bron-crypto Lindell17 swapped operands | **Not present** in Fireblocks MtA (`Enc(k)^x · Enc(β)` shape is correct) |
| ToB threshold inflation | **N/A** — CMP forces `t==n`; FROST is additive 2-of-2 |

## P3 / P4 inventory (this engagement)

| ID | Issue | Tier | Original? | Packaged |
|----|-------|------|-----------|----------|
| **FB-MPC-001** | MTA FS seed `|A|` vs `|S|` heap over-read | **P3** | **Yes** | Yes — submit |
| FB-MPC-003 | Empty `container_cleaner` UB | P3/P4 | No (#56) | Yes — do not re-submit |
| FB-MPC-004 | Misaligned `uint32_t` serializers | P3 | No (#55; our fix broader) | Yes — do not re-submit |
| **FB-MPC-005** | Offline ECDSA finalize skips verify | **P3** | Prior art Zion #07 | Yes — disclose prior art |
| **FB-MPC-006** | FROST peer `D`/`E` not validated | P3/P4 | **Likely yes** | Yes |
| **FB-MPC-007** | Share length unchecked on decrypt | P4 | Likely yes | Yes |
| — | Destructor `OPENSSL_cleanse(sizeof struct)` | was P3 | Fixed on `main` | — |
| — | Quadratic `d_size` overflow / unbounded alloca | was P3 | Mitigated (`MAX_D_SIZE`) | — |

## What to submit for money

1. **FB-MPC-001** — strongest original Medium with ASAN.
2. **FB-MPC-006** — original hygiene / P3–P4; lower payout expectation.
3. **FB-MPC-007** — Low.
4. **FB-MPC-005** — only with prior-art disclosure (Zion #07).
5. Do **not** claim P1/P2 without a new forge/key proof.

## Patches applied in vendor (cloud)

All of FB-MPC-005/006/007 fixes compiled; `cmp_offline_ecdsa` + FROST suites passed after patches.
