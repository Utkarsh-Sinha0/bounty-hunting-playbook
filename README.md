# Fireblocks MPC — bounty research playbook

Autonomous cloud research against the open-source Fireblocks MPC library (`fireblocks/mpc-lib`), scoped to **local find → reproduce → patch → Bugcrowd-ready report**. No live production attacks.

## Strategy (kept)

This program is a **C++ threshold-MPC crypto library**, not a web app. OWASP endpoint fuzzing is the wrong primary surface. The high-signal path is:

1. Read `SECURITY.md`, `SECURITY-MODEL.md`, `CLAUDE.md` (scope, FPs, severity).
2. Build + test the library locally in cloud.
3. Hunt **undeniable code defects** with §1.2 / §4 impact (memory safety, incomplete ZK, co-signer disruption).
4. Reproduce with defensive harnesses (not weaponized key-extraction exploits).
5. Patch + draft a professional Bugcrowd submission.
6. **You** submit on Bugcrowd (agents cannot operate your bounty account).

## Finding index

| ID | Title | Path | Status |
|----|-------|------|--------|
| FB-MPC-001 | Legacy MTA ZKP seed hashes `A` with `S` length (FS truncation) | `findings/FB-MPC-001-mta-zkp-seed-length/` | Ready to submit |

## How to submit FB-MPC-001

1. Open [Fireblocks MPC on Bugcrowd](https://bugcrowd.com/engagements/fireblocks-mbb-og2).
2. Paste / attach contents of `findings/FB-MPC-001-mta-zkp-seed-length/REPORT.md`.
3. Attach `reproduce/reproduce_seed_truncation.cpp` and `patch/mta_seed_length_fix.patch`.
4. Do **not** open a public GitHub security issue (per upstream `SECURITY.md`).

## Local verify

```bash
# Reproduction (no mpc-lib build required)
cd findings/FB-MPC-001-mta-zkp-seed-length/reproduce
g++ -O1 -Wall reproduce_seed_truncation.cpp -o reproduce_seed_truncation -lcrypto
./reproduce_seed_truncation

# Optional: apply patch to a clone of fireblocks/mpc-lib
cd /path/to/mpc-lib
patch -p1 < /path/to/findings/FB-MPC-001-mta-zkp-seed-length/patch/mta_seed_length_fix.patch
```

## P1 bar (Fireblocks SECURITY-MODEL §5.1)

A **Critical / P1** payout requires a working demonstration that an attacker within the malicious-adversary model breaks one of:

1. **Long-term key secrecy** — recover an honest party’s key share, or  
2. **Unforgeability / threshold** — produce a valid signature the honest party did not authorize, or sign without that honest party.

Anything short of that (FS truncation, DoS, memory leak, hardening) is **not P1**, no matter how clean the code bug is.

### Status after P1 hunt (this cloud run)

| Target class | Result |
|--------------|--------|
| Nonce reuse / algebraic nonce leak | Not found in BAM / CMP / FROST / EdDSA signing paths |
| Honest share on wire / reconstructible from honest outbound msgs | Not found |
| Library-internal consumed-nonce resurrection | Not found (presigning delete is integrator contract) |
| Threshold collapse | Not found |
| **FB-MPC-001** (legacy MTA seed truncates `A`) | **Not P1** — incomplete FS on `version < 11`; no end-to-end key-recovery PoC |

I will **not** invent a fake P1 or ship a weaponized key-extraction exploit. Fabricating Critical claims gets N/A and burns reporter reputation.

## Honest expectations

- No payout is guaranteed. Triage may rate FB-MPC-001 as P3/P4, request a fuller forgery chain, or mark mitigated by `MPC_EXTENDED_MTA`.
- Default protocol version is already ≥ 11 (extended seed). Impact is on **legacy negotiated versions**.
- Genuine P1s on this NCC-audited MPC library are rare; continuing research does not guarantee one appears.
