/* Disposable Linux metadata oracle; no production paths or credentials. */
#include <endian.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/xattr.h>

static void require(int ok, const char *message) {
    if (!ok) { perror(message); exit(1); }
}
struct entry { uint16_t tag, permissions; uint32_t id; };
struct acl { uint32_t version; struct entry entries[5]; };

int main(int argc, char **argv) {
    require(argc >= 3, "arguments: seed FILE or compare SOURCE DESTINATION");
    if (strcmp(argv[1], "seed") == 0) {
        struct acl acl = { .version = htole32(2) };
        /* Linux POSIX ACL: owner rw, named synthetic user r, group r, mask r,
           other none. Kernel validation is independent of tar's implementation. */
        const uint16_t tags[] = {1, 2, 4, 16, 32};
        const uint16_t permissions[] = {6, 4, 4, 4, 0};
        for (int i = 0; i < 5; ++i) {
            acl.entries[i].tag = htole16(tags[i]);
            acl.entries[i].permissions = htole16(permissions[i]);
            acl.entries[i].id = htole32(i == 1 ? 12345U : UINT32_MAX);
        }
        require(setxattr(argv[2], "user.backup-test", "synthetic-value", 15, 0) == 0, "set user xattr");
        require(setxattr(argv[2], "system.posix_acl_access", &acl, sizeof acl, 0) == 0, "set POSIX ACL");
    } else {
        require(argc == 4 && strcmp(argv[1], "compare") == 0, "compare arguments");
        const char *names[] = {"user.backup-test", "system.posix_acl_access"};
        for (int i = 0; i < 2; ++i) {
            unsigned char source[1024], destination[1024];
            ssize_t a = getxattr(argv[2], names[i], source, sizeof source);
            ssize_t b = getxattr(argv[3], names[i], destination, sizeof destination);
            require(a > 0 && b == a && memcmp(source, destination, (size_t)a) == 0, names[i]);
        }
    }
    return 0;
}
