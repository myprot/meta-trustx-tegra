EXTRA_OEMAKE = " \
LOCAL_CFLAGS='-std=gnu99 -Icommon -I.. -I../include -I../tpm2d -DDEBUG_BUILD -O2 -Wall -Wextra -Wformat -Wformat-security -Werror -fstack-protector-all -fstack-clash-protection -Wl,-z,noexecstack -Wl,-z,relro -Wl,-z,now -fpic -pie' \
"

SRCREV = "d08bf4b14b5aeaeb013d0c0233c94238c247d9e8"
