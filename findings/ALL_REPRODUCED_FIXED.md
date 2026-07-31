# All reproduced + fixed issues (this engagement)

**None paid yet** (not submitted). All below were **reproduced and patched** in-repo.

Program: Fireblocks MPC (`fireblocks-mbb-og2`) · Target: `fireblocks/mpc-lib`

| ID | Bug | Repro evidence | Patch | Suggested tier | Submit? |
|----|-----|----------------|-------|----------------|---------|
| **FB-MPC-001** | Legacy MTA ZKP seed hashes `A` with `BN_num_bytes(S)` → truncation + **heap over-read** | ASAN + truncation C++ | `findings/FB-MPC-001-…/patch/mta_seed_length_fix.patch` | **P3** (~$3k–$15k) | **Yes — best** |
| **FB-MPC-003** | Empty `container_cleaner` → `OPENSSL_cleanse(&_secret[0])` UB / abort | `_GLIBCXX_ASSERTIONS` abort log | `…/FB-MPC-003-…/patch/container_cleaner_empty_safe.patch` | P3/P4 | **No** — open PR [#56](https://github.com/fireblocks/mpc-lib/pull/56) |
| **FB-MPC-004** | Misaligned `*(uint32_t*)` serializers (full tree) | UBSan misaligned store/load | `…/FB-MPC-004-…/patch/alignment_safe_u32_all_serializers.patch` | P3 | **No** — open PR [#55](https://github.com/fireblocks/mpc-lib/pull/55) (ours is broader) |
| **FB-MPC-005** | Offline ECDSA finalize skips `verify_signature` | `cmp_offline_ecdsa` — corrupt `s` rejected after fix | `…/FB-MPC-005-…/patch/offline_ecdsa_verify_finalize.patch` | P3 | Disclose Zion #07 prior art |
| **FB-MPC-006** | FROST peer nonce points `D`/`E` not validated | FROST suite green after checks | `…/FB-MPC-006-…/patch/frost_validate_DE_points.patch` | P3/P4 | Likely original (hygiene) |
| **FB-MPC-007** | Decrypted share length unchecked before `add_scalars` | Code path + length guard patch | `…/FB-MPC-007-…/patch/share_length_check.patch` | P4 | Likely original (low) |

## Where the files live

```
findings/FB-MPC-001-mta-zkp-seed-length/
findings/FB-MPC-003-container-cleaner-empty/
findings/FB-MPC-004-misaligned-u32-serializers/
findings/FB-MPC-005-offline-ecdsa-missing-verify/
findings/FB-MPC-006-frost-missing-nonce-point-check/
findings/FB-MPC-007-share-length-check/
```

Each has `REPORT.md` + `patch/` + (usually) `reproduce/`.

## Also fixed in vendor clone (not separate Bugcrowd IDs)

Applied under `/workspace/vendor/mpc-lib` during the deep hunt (gitignored vendor):

- Offline verify API change (`signing_data` + `GFp_curve_algebra_verify_signature`)
- FROST `check_a_valid_point` on peer `D`/`E`
- Share length checks in `utils.cpp` + `cmp_setup_service.cpp`
- Broader `byte_io.h` alignment helpers + empty cleaner (same as 003/004)

## Not in this list

- eToro — **nothing** reproduced/fixed
- P1/P2 — **none** found
