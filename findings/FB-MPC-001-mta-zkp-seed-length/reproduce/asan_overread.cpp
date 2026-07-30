// FB-MPC-002 — defensive ASAN reproduction of heap buffer over-read
//
// Bug (mpc-lib mta.cpp generate_mta_range_zkp_seed):
//   std::vector<uint8_t> n(BN_num_bytes(proof.A));
//   BN_bn2bin(proof.A, n.data());
//   SHA256_Update(&ctx, n.data(), BN_num_bytes(proof.S)); // WRONG LENGTH
//
// Reachability: honest prover answers MTA with peer Ring-Pedersen >> peer
// Paillier (setup enforces only minima). Legacy path version < MPC_EXTENDED_MTA.
//
// Build & run:
//   g++ -fsanitize=address -g -O1 asan_overread.cpp -o asan_overread -lcrypto
//   ./asan_overread
// Expect: AddressSanitizer: heap-buffer-overflow

#include <sanitizer/asan_interface.h>
#include <openssl/bn.h>

#include <cstdint>
#include <cstdio>
#include <cstring>
#include <string>
#include <vector>

// Instrumentable stand-in for the out-of-bounds READ that SHA256_Update
// performs on n.data() for `len` bytes (libcrypto itself is not ASAN-ified).
static volatile uint8_t sink;

static void read_bytes_like_sha256_update(const uint8_t* p, size_t len)
{
    for (size_t i = 0; i < len; ++i)
        sink = p[i];
}

static void buggy_seed_step(const BIGNUM* A, const BIGNUM* S)
{
    std::vector<uint8_t> n(static_cast<size_t>(BN_num_bytes(A)));
    BN_bn2bin(A, n.data());

    const size_t have = n.size();
    const size_t want = static_cast<size_t>(BN_num_bytes(S));
    printf("buffer_have=%zu sha_update_len=%zu delta=%zd\n",
           have, want, (ssize_t)want - (ssize_t)have);

    if (want > have) {
        const void* poisoned = __asan_region_is_poisoned(n.data(), want);
        printf("asan_region_is_poisoned(n, want)=%p (non-NULL => over-read would touch poison)\n",
               poisoned);
    }

    // This is the memory-corruption step: reading `want` bytes from `have`-sized buf
    read_bytes_like_sha256_update(n.data(), want);
}

int main()
{
    // Sizes matching peer Paillier 2048 (A ~ |n^2| = 512) vs peer RP 8192 (S ~ 1024)
    BIGNUM* A = BN_new();
    BIGNUM* S = BN_new();
    BN_hex2bn(&A, std::string(1024, 'a').c_str());
    BN_hex2bn(&S, std::string(2048, 'f').c_str());

    printf("A_bytes=%d S_bytes=%d\n", BN_num_bytes(A), BN_num_bytes(S));
    buggy_seed_step(A, S);

    printf("ERROR: expected ASAN abort\n");
    BN_free(A);
    BN_free(S);
    return 1;
}
