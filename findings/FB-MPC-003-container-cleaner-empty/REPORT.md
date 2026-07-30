# FB-MPC-003 — Empty `container_cleaner` undefined behaviour

| Field | Value |
|-------|-------|
| Suggested severity | **P3 Medium** (memory corruption / abort) or **P4 Low** if scoped as local wipe-only |
| Component | `include/utils/string_utils.h` — `container_cleaner` |
| Reachability | Any code path that constructs `string_cleaner` / `byte_vector_cleaner` on an empty secret buffer |
| **Prior art** | **Public open PR [#56](https://github.com/fireblocks/mpc-lib/pull/56)** (2026-06-16). **Not merged** as of 2026-07-30 (`main` @ `00ae08b7`). |
| Submit as original? | **No** — high Bugcrowd duplicate / N-day risk. Use only if program accepts improved fix credits; disclose prior art. |

## When it is raised

Destructor runs:

```cpp
OPENSSL_cleanse(&_secret[0], _secret.size());
```

For an empty `std::vector` / `std::string`, `&_secret[0]` / `operator[](0)` is **undefined behaviour**. With `_GLIBCXX_ASSERTIONS` (common in hardened builds) this **aborts** before wipe.

## Reproduction (local)

```bash
g++ -D_GLIBCXX_ASSERTIONS -g -O0 reproduce/container_cleaner_empty.cpp -o cc_empty -lcrypto
./cc_empty   # aborts: Assertion '__n < this->size()' failed
```

Captured: `reproduce/output.txt` (EXIT 134).

## Fix (better than PR #56)

PR #56 one-liner is correct. This playbook patch keeps the same semantics with clearer empty-guard comments and multi-line structure so future maintainers do not regress OPENSSL_cleanse(null, n) calls:

- Skip wipe when empty
- Use `.data()` instead of `&[0]`
- Document why both matter

Patch: `patch/container_cleaner_empty_safe.patch`

## Why not P1/P2

No key recovery / rogue signature. Crash or UB on empty wipe ≠ Critical/High under this program’s bar.

## Status vs upstream

| Item | Status |
|------|--------|
| Raised | GitHub PR #56, open since 2026-06-16 |
| Merged? | **No** |
| Bug still on `main`? | **Yes** |
| Program tier if novel | P3 (memory) / P4 |
| Original Bugcrowd submit | **Avoid** (duplicate) |
