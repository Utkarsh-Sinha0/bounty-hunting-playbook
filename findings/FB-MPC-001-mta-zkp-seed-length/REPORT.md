# FB-MPC-001 — Incomplete Fiat–Shamir transcript in legacy MTA range ZKP seed

**Program:** Fireblocks MPC (`fireblocks-mbb-og2` / Bugcrowd)  
**Asset:** Open-source `fireblocks/mpc-lib` (`libcosigner`)  
**Component:** `src/common/cosigner/mta.cpp` — `generate_mta_range_zkp_seed`  
**Suggested severity:** P3 Medium / P4 Low (crypto incompleteness on legacy protocol path; mitigated for `version >= MPC_EXTENDED_MTA` (11))  
**CVSS-style impact axis:** Incomplete ZKP / Fiat–Shamir binding (§4.2 SECURITY-MODEL), not demonstrated long-term key recovery  

---

## Summary

In the **legacy** MTA range zero-knowledge proof seed derivation (`version < MPC_EXTENDED_MTA`), the prover/verifier hash field `proof.A` into the Fiat–Shamir transcript using **`BN_num_bytes(proof.S)` as the length**, while the buffer was filled from `proof.A`:

```cpp
std::vector<uint8_t> n(BN_num_bytes(proof.A));
BN_bn2bin(proof.A, n.data());
SHA256_Update(&ctx, n.data(), BN_num_bytes(proof.S)); // BUG
```

Under production CMP auxiliary-key sizes (`PAILLIER_KEY_SIZE = 2048`, `RING_PEDERSEN_KEY_SIZE = 1024`):

| Field | Typical `BN_num_bytes` after deserialize |
|-------|------------------------------------------|
| `A` (Paillier \(n^2\)) | ≈ 512 |
| `S` (Ring-Pedersen \(n\)) | ≈ 128 |

So the call **truncates** `A`: only the high-order ~128 bytes of `A` enter the transcript. Low-order bytes of `A` can change without changing the derived challenge seed.

The modern path (`generate_mta_range_zkp_extended_seed`, `version >= 11`) already hashes `A` with fixed width `2 * paillier_n_size`, which strongly suggests this legacy defect was known and replaced rather than fixed in place.

---

## Threat model mapping (SECURITY-MODEL.md)

| Item | Statement |
|------|-----------|
| Attacker | Malicious co-signer in a protocol run with negotiated `version < 11` (still allowed: `MPC_MIN_SUPPORTED_PROTOCOL_VERSION = 2`) |
| Capability | Choose `A` (and other proof fields) within deserialize epsilon bounds; messages authenticated per integrator transport contract |
| §1.2 property at risk | Soundness of the MTA range ZKP (incomplete binding of announcement `A` in FS) — may enable forged proofs if the unbound degrees of freedom can be completed into a §1.2 break |
| Not claimed | End-to-end recovery of an honest party’s long-term key share (no key-extraction PoC in this report) |
| Not a §3 / §6 FP | Not attacker self-harm; not identity-element ZKP; not `drng_*` determinism; not integrator persistency |

---

## Steps to reproduce (local, defensive)

1. Clone `https://github.com/fireblocks/mpc-lib` (any recent `main`).
2. Inspect `src/common/cosigner/mta.cpp` lines ~128–130 (function `generate_mta_range_zkp_seed`).
3. Build and run the defensive harness in `reproduce/`:

```bash
g++ -O1 -Wall reproduce_seed_truncation.cpp -o reproduce_seed_truncation -lcrypto
./reproduce_seed_truncation
```

4. **Expected (bug present):** `buggy(A1)` digest equals `buggy(A2)` when `A1`/`A2` share the same high-order 128 bytes but differ in low-order bytes; `fixed(A1)` ≠ `fixed(A2)`.
5. **Actual:** Harness prints `PASS` for both checks (exit code 0).

Optional ASAN check (non-production sizes where `len(S) > len(A)`): the same length mismatch would heap over-read; production deserialize epsilon checks make that ordering unreachable after wire parse, but the wrong length remains.

---

## Reachability

- Called from prover and verifier when `version < MPC_EXTENDED_MTA` (`mta.cpp` ~552, ~988, ~1596).
- Setup stores negotiated min version (`cmp_setup_service.cpp`: `temp_data.version = version`).
- Current `MPC_PROTOCOL_VERSION = 13` uses the extended seed by default; **legacy path remains compiled and live for mixed-version / older peers**.

---

## Impact

1. **Fiat–Shamir incompleteness:** announcement `A` is not fully bound into the challenge for legacy MTA range proofs.
2. **Memory-safety class hazard:** the same line is a heap buffer over-read whenever `BN_num_bytes(S) > BN_num_bytes(A)` (not the production size ordering after deserialize checks).
3. **Why Fireblocks already added `MPC_EXTENDED_MTA`:** the extended seed uses fixed-width `hash_bn` for `A`/`S`/…, which is the correct FS encoding.

We do **not** claim a full §1.2.1/§1.2.2 break without a completed forgery chain. Per §4.7, cryptographic incompleteness remains in-scope even when practical exploitation is unfinished; severity should reflect that.

---

## Fix

Minimal patch (see `patch/mta_seed_length_fix.patch`):

```cpp
SHA256_Update(&ctx, n.data(), BN_num_bytes(proof.A));
```

Stronger remediation (recommended):

1. Apply the length fix above for correctness of the variable-length encoding, **or**
2. Prefer rejecting `version < MPC_EXTENDED_MTA` for signing, forcing the already-correct extended seed path.

Note: changing the legacy seed formula breaks wire compatibility with already-deployed buggy peers on `version < 11`. Coordinated upgrade or version floor is appropriate.

---

## Out of scope / not this finding

- Integrator persistency / transport (§2)
- Point-at-infinity ZKP acceptance (§3.2 / §6.6)
- `drng_*` determinism (§6.2)
- BAM ECDSA v13 default path (uses different proofs; this bug is CMP MTA legacy seed only)

---

## Attachments

- `reproduce/reproduce_seed_truncation.cpp` — defensive transcript collision demo  
- `patch/mta_seed_length_fix.patch` — one-line fix  

## Reporter notes for triage

Please treat this as a **code-defect + FS incompleteness** report with a local deterministic reproduction, not a black-box production attack. Happy to iterate if triage wants an end-to-end forged-proof construction against the MTA range verifier under `version < 11`.
