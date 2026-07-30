# Fireblocks MPC — bounty research playbook

Autonomous cloud research against open-source `fireblocks/mpc-lib`: **local find → reproduce → patch → Bugcrowd-ready report**.

## Finding index

| ID | Title | Suggested tier | Status |
|----|-------|----------------|--------|
| FB-MPC-001 | Legacy MTA seed: heap over-read when peer RP ≫ Paillier; FS truncation at default sizes | **P3 Medium** (memory corruption) | Ready to submit |

## Why not P2 / multiple P3s (this run)

| Ask | Result |
|-----|--------|
| **P2 High** | Requires key / rogue signature with &lt;1e9 aborts. **Not found.** Will not fabricate. |
| **Multiple distinct P3s** | Second independent memory-corruption defect **not found** after dedicated hunt (BAM/FROST/EdDSA/deserialize paths). |
| **FB-MPC-001** | One root bug, two manifestations (truncation + over-read). Submit as **single** Medium finding with ASAN proof. |

## Submit FB-MPC-001

1. Open [Fireblocks MPC on Bugcrowd](https://bugcrowd.com/engagements/fireblocks-mbb-og2).
2. Use `findings/FB-MPC-001-mta-zkp-seed-length/REPORT.md`.
3. Attach ASAN + truncation repros and `patch/mta_seed_length_fix.patch`.
4. Do **not** open a public GitHub security issue.

## Local verify

```bash
cd findings/FB-MPC-001-mta-zkp-seed-length/reproduce

# P3 memory corruption (expect ASAN abort)
g++ -fsanitize=address -g -O1 asan_overread.cpp -o asan_overread -lcrypto
./asan_overread

# FS truncation under default sizes (expect exit 0)
g++ -O1 -Wall reproduce_seed_truncation.cpp -o reproduce_seed_truncation -lcrypto
./reproduce_seed_truncation
```

## P1/P2 bar (program text)

- **Critical:** retrieve key or rogue signature (&lt;1000 aborts / none)
- **High:** same with &lt;1e9 aborts
- **Medium:** leak key bits **or cause memory corruption**
- **Low:** narrower non-critical exposure
