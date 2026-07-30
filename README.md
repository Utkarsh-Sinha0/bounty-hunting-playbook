# Fireblocks MPC — bounty research playbook

Autonomous cloud research against open-source `fireblocks/mpc-lib`: **local find → reproduce → patch → Bugcrowd-ready report**.

## Finding index

| ID | Title | Suggested tier | Submit? | Status |
|----|-------|----------------|---------|--------|
| **FB-MPC-001** | Legacy MTA seed: heap over-read when peer RP ≫ Paillier; FS truncation at default sizes | **P3 Medium** | **Yes (original)** | Ready |
| FB-MPC-003 | Empty `container_cleaner` UB (abort under assertions) | P3/P4 | **No — duplicate of [#56](https://github.com/fireblocks/mpc-lib/pull/56)** | Reproduced; improved patch packaged |
| FB-MPC-004 | Misaligned `uint32_t` serializers (UBSan) | P3 | **No — duplicate of [#55](https://github.com/fireblocks/mpc-lib/pull/55)** (our fix is broader) | Reproduced; full-tree patch packaged |

See `findings/DEEP_HUNT_P2_P3.md` for the P1/P2 negative result.

## #55 / #56 — raised when? merged?

| PR | Raised | Merged into `main`? | Bug still present? | Program map |
|----|--------|---------------------|--------------------|-------------|
| [#55](https://github.com/fireblocks/mpc-lib/pull/55) misaligned `uint32_t` | 2026-06-15 | **No** (`merged_at: null`) | **Yes** on tip `00ae08b7` (2026-07-30) | **P3** memory UB (not P1/P2) |
| [#56](https://github.com/fireblocks/mpc-lib/pull/56) empty `container_cleaner` | 2026-06-16 | **No** | **Yes** (local abort reproduced) | **P3/P4** (not P1/P2) |

Neither is Critical/High under Bugcrowd: no key recovery or rogue signature.

## P1 / P2 (money tiers)

| Tier | Bar | This engagement |
|------|-----|-----------------|
| **P1 Critical** | Key or rogue signature (&lt;1000 aborts / none) | **Not found** |
| **P2 High** | Same with &lt;1e9 aborts | **Not found** |
| **P3 Medium** | Leak key bits **or memory corruption** | **FB-MPC-001** (original); #55/#56 class already public |

Do not fabricate Critical findings. Fabricated or weaponized key-extraction claims will get you banned, not tuition.

## Submit FB-MPC-001 only

1. Open [Fireblocks MPC on Bugcrowd](https://bugcrowd.com/engagements/fireblocks-mbb-og2).
2. Use `findings/FB-MPC-001-mta-zkp-seed-length/REPORT.md`.
3. Attach ASAN + truncation repros and `patch/mta_seed_length_fix.patch`.
4. Do **not** open a public GitHub security issue.
5. Do **not** re-submit #55/#56 as original; if you open a GitHub fix PR, credit prior art and prefer the broader FB-MPC-004 patch.

## Local verify

```bash
# FB-MPC-001
cd findings/FB-MPC-001-mta-zkp-seed-length/reproduce
g++ -fsanitize=address -g -O1 asan_overread.cpp -o asan_overread -lcrypto && ./asan_overread

# FB-MPC-003 (known-public #56)
cd ../../FB-MPC-003-container-cleaner-empty/reproduce
g++ -D_GLIBCXX_ASSERTIONS -g -O0 container_cleaner_empty.cpp -o cc_empty -lcrypto && ./cc_empty

# FB-MPC-004 (known-public #55 class)
cd ../../FB-MPC-004-misaligned-u32-serializers/reproduce
g++ -fsanitize=alignment -g -O1 ubsan_unaligned_u32.cpp -o ubsan_u32 && ./ubsan_u32
```
