# Fireblocks MPC — bounty research playbook

Autonomous cloud research against open-source `fireblocks/mpc-lib`: **local find → reproduce → patch → Bugcrowd-ready report**.

## Finding index

| ID | Title | Tier | Submit? |
|----|-------|------|---------|
| **FB-MPC-001** | Legacy MTA seed: heap over-read / FS truncation | **P3** | **Yes (original)** |
| FB-MPC-003 | Empty `container_cleaner` UB | P3/P4 | No — duplicate [#56](https://github.com/fireblocks/mpc-lib/pull/56) |
| FB-MPC-004 | Misaligned `uint32_t` serializers | P3 | No — duplicate [#55](https://github.com/fireblocks/mpc-lib/pull/55) (broader fix packaged) |
| FB-MPC-005 | Offline ECDSA finalize skips signature verify | P3 | Disclose prior art (Zion #07) |
| **FB-MPC-006** | FROST peer nonce points `D`/`E` not validated | P3/P4 | **Likely original** |
| FB-MPC-007 | Decrypted share length unchecked | P4 | Likely original |

## P1 / P2 (tuition tiers)

**None found** after a parallel crypto-hunt team pass (setup, MtA/ZKP, FROST/BAM, memory, public research cross-check).

External “8-bit batch gamma ⇒ P2 @ 1/256” is a **mis-model** of Fireblocks’ 5×8-bit = **~40-bit** batch soundness. Details: `findings/DEEP_HUNT_TEAM_P1_P2.md`.

| Tier | Bar | Result |
|------|-----|--------|
| P1 Critical | Key or rogue signature (&lt;1000 aborts) | **Not found** |
| P2 High | Same with &lt;1e9 aborts | **Not found** |

## #55 / #56 status

Both **open, not merged** as of 2026-07-30. Still on `main`. Map to **P3/P4**, not P1/P2.

## Submit guidance

1. Ship **FB-MPC-001** first (ASAN Medium).
2. Optionally FB-MPC-006 / 007 as smaller originals.
3. Do not invent Critical findings.

## Local verify (high level)

```bash
# FB-MPC-001 ASAN
cd findings/FB-MPC-001-mta-zkp-seed-length/reproduce
g++ -fsanitize=address -g -O1 asan_overread.cpp -o asan_overread -lcrypto && ./asan_overread

# Vendor suites after FB-MPC-005/006 patches
./build/test/cosigner/cosigner_test cmp_offline_ecdsa
./build/test/cosigner/cosigner_test frost,frost_attacks
```
