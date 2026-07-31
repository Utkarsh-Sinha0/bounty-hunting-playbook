# FB-MPC-005 — Offline ECDSA finalize skips signature verification

| Field | Value |
|-------|-------|
| Suggested severity | **P3 Medium** (protocol integrity: returns invalid aggregated signatures) |
| Component | `cmp_ecdsa_offline_signing_service::ecdsa_offline_signature` |
| Contrast | Online path calls `GFp_curve_algebra_verify_signature` before return |
| Prior art | Publicly discussed as Zion Boggan notebook finding **#07** (2026-04). Disclose prior art if submitting. |
| Submit as original? | **Risky** — treat as known-class unless Bugcrowd has no prior report |

## Bug

Offline finalize only checks matching `r`/`v` across players and sums `s`. It never verifies `(r,s)` under the derived public key and message. A corrupted / malicious partial `s` yields an **invalid** signature that the library still returns successfully. Online finalize would throw.

This is **not** rogue-signature / key-extraction (P1/P2): the output fails EC verify. It violates the library’s own “successful run ⇒ valid signature” expectation and can ship bad sigs to callers that trust the library.

## Reproduction

Patched unit test corrupts one peer’s `s` then expects finalize to throw:

```
failed to verify offline signature for block 0, error -7
All tests passed (506 assertions in 1 test case)
```

See `reproduce/test_output_excerpt.txt`. Run:

```bash
./build/test/cosigner/cosigner_test cmp_offline_ecdsa
```

## Fix

Require `signing_data` on finalize (messages + paths), derive pubkey from key metadata, call `GFp_curve_algebra_verify_signature` per block — same as online.

Patch: `patch/offline_ecdsa_verify_finalize.patch`
