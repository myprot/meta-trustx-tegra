SRC_URI += "file://trustx.cfg \
	"

L4T_VERSION = "l4t-r32.6"
SRCBRANCH = "oe4t-patches-${L4T_VERSION}"
SRCREV = "3b1a82dc339456b28fc75d4c1428d4ec3b6b9d95"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

do_preconfigure () {
        cat ${WORKDIR}/trustx.cfg >> ${WORKDIR}/defconfig
}

addtask do_preconfigure after do_patch before do_configure
