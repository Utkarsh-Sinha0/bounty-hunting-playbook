// Documents publicly known UB from fireblocks/mpc-lib PR #56 (do NOT submit as original).
#include <vector>
#include <cstdio>
#include <openssl/crypto.h>
template <typename T>
struct container_cleaner {
    explicit container_cleaner(T& s) : _secret(s) {}
    ~container_cleaner() { OPENSSL_cleanse(&_secret[0], _secret.size()); }
    T& _secret;
};
int main() {
    std::vector<unsigned char> v;
    container_cleaner<std::vector<unsigned char>> c(v);
    return 0;
}
