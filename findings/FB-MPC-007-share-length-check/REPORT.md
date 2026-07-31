# FB-MPC-007 — Decrypted additive shares accepted at arbitrary length

| Field | Value |
|-------|-------|
| Suggested severity | **P4 Low** (input validation / hardening) |
| Component | `decrypt_and_rebuild_private_share`, CMP setup share import |
| Contrast | Offline refresh already rejects wrong-length seeds (`sizeof(commitments_sha256_t)`) |
| Prior art | Pattern noted in deep hunt; not in open memory PRs #54–#56 |

## Bug

Decrypted peer shares are fed to `add_scalars(..., share.size())` with no length check. Wrong lengths do not ASAN-crash (BN absorbs the bytes) but can corrupt reconstruction until a later pubkey consistency failure — weaker fail-closed than sibling paths.

## Fix

Require `share.size() == sizeof(elliptic_curve256_scalar_t)` before `add_scalars` in:
- `utils.cpp` (`decrypt_and_rebuild_private_share`)
- `cmp_setup_service.cpp` (setup share import)

Patch: `patch/share_length_check.patch`
