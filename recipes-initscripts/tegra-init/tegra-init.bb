LICENSE = "MIT"


LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"


FILES_${PN} = "${sysconfdir}/*"
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI = " file://run-script.sh"

RDEPENDS_${PN} = "bash"

do_install () {
        install -d ${D}${sysconfdir}
        install -d ${D}${sysconfdir}/init.d
        install -d ${D}${sysconfdir}/rc5.d

        install -m 0755 ${WORKDIR}/run-script.sh      ${D}${sysconfdir}/init.d/
        ln -sf ../init.d/run-script.sh      ${D}${sysconfdir}/rc5.d/S90run-script
}

