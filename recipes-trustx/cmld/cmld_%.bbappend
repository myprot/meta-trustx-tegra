XTRA_OEMAKE = "TRUSTME_HARDWARE=${TRUSTME_HARDWARE} \
LOCAL_CFLAGS='-std=gnu99 -Icommon -I.. -I../include -I../tpm2d -DDEBUG_BUILD -O2 -Wall -Wextra -Wformat -Wformat-security -Werror -fstack-protector-all -fstack-clash-protection -Wl,-z,noexecstack -Wl,-z,relro -Wl,-z,now -fpic -pie -DTPM_POSIX'"
