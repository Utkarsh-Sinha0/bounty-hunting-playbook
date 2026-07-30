# FB-MPC-004 — Misaligned `uint32_t` length-prefix serializers (UBSan)

| Field | Value |
|-------|-------|
| Suggested severity | **P3 Medium** (memory corruption / UB; SIGBUS risk on strict-alignment CPUs) |
| Component | Length-prefixed serializers after variable-length BN payloads |
| Reachability | Serialize/deserialize of Ring-Pedersen, Damgård–Fujisaki, range proofs, Paillier ZKP, Paillier commitment, MTA range ZKP, BAM well-formed proofs — including **peer-supplied** deserialize paths |
| **Prior art** | **Public open PR [#55](https://github.com/fireblocks/mpc-lib/pull/55)** (2026-06-15). **Not merged** as of 2026-07-30. |
| Submit as original? | **No** — prior art covers the bug class. This package is a **broader fix** than #55. |

## When it is raised

Legacy pattern:

```c
*(uint32_t*)ptr = n_len;           // store
n_len = *(const uint32_t*)ptr;     // load
```

After an odd-length `BN_bn2bin` payload, `ptr` is often **not 4-byte aligned**. That is undefined behaviour; UBSan reports it; aarch64 can SIGBUS.

## Reproduction (minimal model)

```bash
g++ -fsanitize=alignment -g -O1 reproduce/ubsan_unaligned_u32.cpp -o ubsan_u32
./ubsan_u32        # UBSan: store/load to misaligned address
./ubsan_u32 safe   # clean (memcpy helpers)
```

Captured: `reproduce/ubsan_legacy_output.txt`, `reproduce/ubsan_safe_output.txt`.

Upstream PR #55 also shows UBSan on real `ring_pedersen` / `damgard_fujisaki` round-trips.

## Fix (better than PR #55)

PR #55 correctly introduces `byte_io.h` and patches **ring_pedersen.c** + **damgard_fujisaki.c** only.

Same class of UB remains in other production serializers. This playbook patch:

1. Keeps `store_u32` / `load_u32` via `memcpy` (host-endian preserved)
2. Adds C `extern "C"` guards + rationale comments in `byte_io.h`
3. Converts **all** production sites found on `main`:
   - `ring_pedersen.c`, `damgard_fujisaki.c` (same as #55)
   - `range_proofs.c`, `paillier_zkp.c`, `paillier_commitment.c`
   - `mta.cpp`, `bam_well_formed_proof.cpp`
4. Avoids double-`load_u32` in MTA error logs (load once into locals)

Patch: `patch/alignment_safe_u32_all_serializers.patch`

Verified: `paillier_test`, `zero_knowledge_proof_test`, `paillier_commitment_test`, `pedersen_commitment_test` all pass after the change.

## Why not P1/P2

Misaligned access is memory UB / potential crash — maps to **P3 memory corruption**, not key extraction or rogue signature.

## Status vs upstream

| Item | Status |
|------|--------|
| Raised | GitHub PR #55, open since 2026-06-15 |
| Merged? | **No** |
| Bug still on `main`? | **Yes** (also outside #55’s file scope) |
| Program tier if novel | P3 |
| Original Bugcrowd submit | **Avoid** for the known sites; improved full-tree patch may be useful as a **vendor fix PR**, not a duplicate bounty |
