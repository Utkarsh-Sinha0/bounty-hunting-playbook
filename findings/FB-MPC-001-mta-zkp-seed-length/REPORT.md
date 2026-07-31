# FB-MPC-001 — Heap buffer over-read in legacy MTA range ZKP seed (memory corruption)

**Program:** Fireblocks MPC Managed Bug Bounty (`fireblocks-mbb-og2`)  
**Target:** `github.com/fireblocks/mpc-lib`  
**Component:** `src/common/cosigner/mta.cpp` — `generate_mta_range_zkp_seed`  
**Suggested Bugcrowd tier:** **Medium / P3** — *“causing memory corruption”*  
**Also:** Incomplete Fiat–Shamir binding of field `A` under default key sizes (secondary)

---

## Summary

Legacy MTA range ZKP seed derivation (`version < MPC_EXTENDED_MTA` = 11) does:

```cpp
std::vector<uint8_t> n(BN_num_bytes(proof.A));
BN_bn2bin(proof.A, n.data());
SHA256_Update(&ctx, n.data(), BN_num_bytes(proof.S)); // BUG: length from S
```

That is a **cross-field length mismatch**: buffer sized for `A`, length taken from `S`.

| Peer key sizes (allowed by setup) | Effect |
|-----------------------------------|--------|
| Default CMP: Paillier 2048, RP 1024 | `S < A` → **truncates** `A` in Fiat–Shamir transcript |
| Peer RP larger than Paillier \(n^2\) (e.g. RP 4096/8192, Paillier 2048) | `S > A` → **heap buffer over-read** on honest prover |

Setup (`cmp_setup_service.cpp`) only enforces **minimum** Paillier/RP sizes — **no maximum**. A malicious co-signer can publish an oversized Ring-Pedersen public key that still passes `ring_pedersen_public_size >= RING_PEDERSEN_KEY_SIZE`.

---

## Why this is in-scope Medium (P3)

Bugcrowd rating for this engagement:

> **Medium** — Leaking bits of the private key or **causing memory corruption**.

ASAN demonstrates a definitive **heap-buffer-overflow READ** for the `S > A` size relationship that peer keys can force on the honest MTA prover.

Maps to Fireblocks SECURITY-MODEL **§4.3** (malformed/adversarial peer input must not crash or corrupt honest co-signer memory) and **§4.2** (incomplete ZKP / FS binding when `S < A`).

---

## Reachability (honest prover)

1. Attacker publishes auxiliary keys: Paillier ≥ 2048 (min OK) and Ring-Pedersen **≫** Paillier (e.g. 8192-bit). Setup accepts (min-only checks at `cmp_setup_service.cpp` ~795–811).
2. Signing negotiates `version < 11` (attacker advertises old MPC version; `mta_response` uses passed `version` when `version <= metadata.version` — `cmp_ecdsa_online_signing_service.cpp` ~148–160). Keys created under old setup versions also retain legacy path.
3. Honest party runs `answer_mta_request` → `mta_range_generate_zkp` with **peer** `ring_pedersen` and **peer** `paillier` (`mta.cpp` ~764–775, called from `cmp_ecdsa_signing_service.cpp` ~114–117).
4. Proof generation builds:
   - `A` under peer Paillier → ~`2 * |n_p|` bytes  
   - `S` under peer RP → ~`|n_rp|` bytes  
5. With `version < 11`, `generate_mta_range_zkp_seed` over-reads `n.data()` by `|S|-|A|` bytes.

Modern default `MPC_PROTOCOL_VERSION = 13` uses the fixed extended seed — **legacy negotiated versions remain reachable**.

---

## Proof of concept (ASAN)

```bash
cd findings/FB-MPC-001-mta-zkp-seed-length/reproduce   # or FB-MPC-002 path
g++ -fsanitize=address -g -O1 asan_overread.cpp -o asan_overread -lcrypto
./asan_overread
```

**Observed:**

```
A_bytes=512 S_bytes=1024
...
ERROR: AddressSanitizer: heap-buffer-overflow
READ of size 1 at ...
0x... is located 0 bytes after 512-byte region
SUMMARY: AddressSanitizer: heap-buffer-overflow ... in read_bytes_like_sha256_update
```

(See attached `asan_output.txt`.)

The instrumented loop mirrors the out-of-bounds read implied by `SHA256_Update(buf, len=S)` on an `A`-sized buffer (libcrypto itself is not ASAN-instrumented).

### Secondary: FS truncation under default sizes

```bash
g++ -O1 -Wall reproduce_seed_truncation.cpp -o reproduce_seed_truncation -lcrypto
./reproduce_seed_truncation
```

Two `A` values that share the same high-order 128 bytes but differ in low-order bytes produce **identical** buggy seeds and **different** fixed seeds.

---

## Impact

1. **Memory corruption (P3):** Peer-triggerable heap over-read on honest co-signer during legacy MTA proof generation → crash / potential info leak from adjacent heap (ASAN-confirmed class).
2. **Incomplete FS:** Under default sizes, low-order bytes of `A` are unbound in the challenge (soundness degradation of legacy MTA range ZKP).
3. **Not claimed:** End-to-end long-term key recovery / rogue signature (would be Critical/High). No weaponized key-extraction exploit is included.

---

## Fix

```diff
-    SHA256_Update(&ctx, n.data(), BN_num_bytes(proof.S));
+    SHA256_Update(&ctx, n.data(), BN_num_bytes(proof.A));
```

Stronger: reject `version < MPC_EXTENDED_MTA` for signing, and/or cap Ring-Pedersen size relative to Paillier at setup.

Patch file: `patch/mta_seed_length_fix.patch`

---

## Out of scope / not this finding

- Integrator persistency / transport (§2)  
- Point-at-infinity ZKP (§3.2 / §6.6)  
- `drng_*` determinism (§6.2)  
- BAM ECDSA v13 default path (different proof stack)

---

## Attachments

- `reproduce/asan_overread.cpp` + `asan_output.txt`  
- `reproduce/reproduce_seed_truncation.cpp` + `output.txt`  
- `patch/mta_seed_length_fix.patch`
