// Defensive reproduction for FB-MPC-001
// Demonstrates that generate_mta_range_zkp_seed (legacy) hashes proof.A
// with BN_num_bytes(proof.S) instead of BN_num_bytes(proof.A).
//
// Under production CMP key sizes (Paillier 2048, Ring-Pedersen 1024):
//   BN_num_bytes(A) ≈ 512, BN_num_bytes(S) ≈ 128
// so the call truncates A — low-order bytes of A are unbound in the
// Fiat–Shamir transcript.
//
// Build:
//   g++ -O1 -Wall reproduce_seed_truncation.cpp -o reproduce_seed_truncation -lcrypto
// Run:
//   ./reproduce_seed_truncation

#include <openssl/bn.h>
#include <openssl/sha.h>

#include <cstdint>
#include <cstdio>
#include <cstring>
#include <string>
#include <vector>

static const uint8_t MTA_ZKP_SALT[] = "Fireblocks MTA ZKP";

// Mirrors mta.cpp generate_mta_range_zkp_seed A-hash step (BUGGY).
static void legacy_hash_A_buggy(const BIGNUM* A, const BIGNUM* S, uint8_t out[32])
{
    SHA256_CTX ctx;
    SHA256_Init(&ctx);
    SHA256_Update(&ctx, MTA_ZKP_SALT, sizeof(MTA_ZKP_SALT));

    std::vector<uint8_t> n(BN_num_bytes(A));
    BN_bn2bin(A, n.data());
    // BUG: length taken from S, buffer filled from A
    SHA256_Update(&ctx, n.data(), BN_num_bytes(S));

    SHA256_Final(out, &ctx);
}

// Corrected: hash A with A's own byte length.
static void legacy_hash_A_fixed(const BIGNUM* A, const BIGNUM* /*S*/, uint8_t out[32])
{
    SHA256_CTX ctx;
    SHA256_Init(&ctx);
    SHA256_Update(&ctx, MTA_ZKP_SALT, sizeof(MTA_ZKP_SALT));

    std::vector<uint8_t> n(BN_num_bytes(A));
    BN_bn2bin(A, n.data());
    SHA256_Update(&ctx, n.data(), BN_num_bytes(A));

    SHA256_Final(out, &ctx);
}

static BIGNUM* bn_from_hex(const std::string& hex)
{
    BIGNUM* bn = nullptr;
    BN_hex2bn(&bn, hex.c_str());
    return bn;
}

static void print_digest(const char* label, const uint8_t d[32])
{
    printf("%s: ", label);
    for (int i = 0; i < 32; ++i)
        printf("%02x", d[i]);
    printf("\n");
}

int main()
{
    // Production-like sizes: A ~512 bytes (Paillier n^2), S ~128 bytes (RP n)
    BIGNUM* A1 = bn_from_hex(std::string(1024, 'a')); // 512 bytes
    BIGNUM* S = bn_from_hex(std::string(256, 'b'));    // 128 bytes

    // A2 identical in the high-order 128 bytes, different in low-order bytes.
    // BN_bn2bin is big-endian, so first 128 bytes hashed by the buggy path
    // are the MSBs — flip LSBs by changing the last hex nibbles.
    std::string a2hex(1024, 'a');
    for (int i = 0; i < 64; ++i)
        a2hex[a2hex.size() - 1 - i] = 'c';
    BIGNUM* A2 = bn_from_hex(a2hex);

    printf("A1_bytes=%d A2_bytes=%d S_bytes=%d\n",
           BN_num_bytes(A1), BN_num_bytes(A2), BN_num_bytes(S));
    printf("Expected truncation: buggy path hashes only first %d of %d A bytes\n\n",
           BN_num_bytes(S), BN_num_bytes(A1));

    uint8_t h1_buggy[32], h2_buggy[32], h1_fixed[32], h2_fixed[32];
    legacy_hash_A_buggy(A1, S, h1_buggy);
    legacy_hash_A_buggy(A2, S, h2_buggy);
    legacy_hash_A_fixed(A1, S, h1_fixed);
    legacy_hash_A_fixed(A2, S, h2_fixed);

    print_digest("buggy(A1)", h1_buggy);
    print_digest("buggy(A2)", h2_buggy);
    print_digest("fixed(A1)", h1_fixed);
    print_digest("fixed(A2)", h2_fixed);

    const bool buggy_collision = memcmp(h1_buggy, h2_buggy, 32) == 0;
    const bool fixed_differs = memcmp(h1_fixed, h2_fixed, 32) != 0;

    printf("\n");
    if (buggy_collision)
        printf("PASS: buggy seeds COLLIDE — low-order A bytes unbound in FS transcript\n");
    else
        printf("FAIL: buggy seeds unexpectedly differ\n");

    if (fixed_differs)
        printf("PASS: fixed seeds DIFFER — full A is bound\n");
    else
        printf("FAIL: fixed seeds unexpectedly collide\n");

    BN_free(A1);
    BN_free(A2);
    BN_free(S);

    return (buggy_collision && fixed_differs) ? 0 : 1;
}
