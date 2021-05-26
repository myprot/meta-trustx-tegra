SRC_URI += "file://trustx.cfg \
	"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

do_preconfigure () {
        cat ${WORKDIR}/trustx.cfg >> ${WORKDIR}/defconfig
}

addtask do_preconfigure after do_patch before do_configure
