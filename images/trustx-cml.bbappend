require recipes-core/images/core-image-minimal.bb
inherit trustmetegra

IMAGE_FSTYPES = "tegraflash trustmetegra"
DEPENDS += " bash-native bash "


PACKAGE_INSTALL_append = "\
        ${VIRTUAL-RUNTIME_base-utils} \
        udev \
        base-passwd \
        base-files \
        shadow \
        mingetty \
        libselinux \
        cmld \
        service-static \
        control \
        scd \
        iptables \
        ibmtss2 \
        tpm2d \
        rattestation \
        stunnel \
        openssl-tpm2-engine \
        sc-hsm-embedded \
        e2fsprogs-mke2fs \
        e2fsprogs-e2fsck \
        btrfs-tools \
        ${ROOTFS_BOOTSTRAP_INSTALL} \
        cml-boot \
        iproute2 \
        lxcfs \
        pv \
        uid-wrapper \
"

PACKAGE_INSTALL_append = "\
        openssl-bin \
        gptfdisk \
        parted \
        util-linux-sfdisk \
"

