// Minimal model of fireblocks/mpc-lib serializers: write uint32 after an
// odd-length BN-style payload so the next length field is unaligned.
// Compile with -fsanitize=alignment to observe UBSan on the legacy form.
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <string>
#include <vector>

static void legacy_store(uint8_t *p, uint32_t v) {
    *(uint32_t *)p = v; // intentional UB when p is misaligned
}

static uint32_t legacy_load(const uint8_t *p) {
    return *(const uint32_t *)p;
}

static void safe_store(uint8_t *p, uint32_t v) {
    memcpy(p, &v, sizeof(v));
}

static uint32_t safe_load(const uint8_t *p) {
    uint32_t v;
    memcpy(&v, p, sizeof(v));
    return v;
}

int main(int argc, char **argv) {
    const bool use_safe = (argc > 1 && std::string(argv[1]) == "safe");
    // 1-byte BN payload then length field → offset 1 (misaligned)
    std::vector<uint8_t> buf(1 + 4 + 4, 0);
    buf[0] = 0xAB;
    uint8_t *len1 = buf.data() + 1;
    uint8_t *len2 = buf.data() + 5;
    if (use_safe) {
        safe_store(len1, 0x11111111u);
        safe_store(len2, 0x22222222u);
        printf("safe load1=%08x load2=%08x\n", safe_load(len1), safe_load(len2));
    } else {
        legacy_store(len1, 0x11111111u);
        legacy_store(len2, 0x22222222u);
        printf("legacy load1=%08x load2=%08x\n", legacy_load(len1), legacy_load(len2));
    }
    return 0;
}
