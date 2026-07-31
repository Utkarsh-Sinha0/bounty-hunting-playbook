# FB-MPC-006 — FROST signing accepts unverified peer nonce points `D`/`E`

| Field | Value |
|-------|-------|
| Suggested severity | **P3 / P4** (defense-in-depth; peer can inject infinity / invalid points) |
| Component | `frost_cosigner_client` / `frost_cosigner_server` signing round |
| Contrast | BAM ECDSA validates peer `R` via `check_a_valid_point` before use |
| Prior art | None found in open GitHub PRs or Zion notebook — **likely original** |
| P1/P2? | **No** — infinity / invalid nonces degrade the attacker’s own contribution; honest share not extracted |

## Bug

Client binds `server_share.D/E` into the common nonce without validating them. Server binds `partial_signature.D/E` without validation. BAM’s sibling path validates peer points.

## Reproduction / verification

FROST suite still green after adding validation:

```
All tests passed (44387 assertions in 6 test cases)
```

(`frost`, `frost_attacks`, nonce uniqueness, tenant, zero-scalar, add-user)

## Fix

Call existing `frost_cosigner::check_a_valid_point` on peer `D` and `E` before `compute_common_nonce`.

Patch: `patch/frost_validate_DE_points.patch`
