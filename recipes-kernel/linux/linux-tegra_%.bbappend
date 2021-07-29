SRC_URI += "file://trustx.cfg \
	"

L4T_VERSION = "l4t-r32.5"
SRCBRANCH = "oe4t-patches-${L4T_VERSION}"
SRCREV = "a3633e2e1cf4c7309a88303f06ee4eb20188c716"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

do_preconfigure () {
        cat ${WORKDIR}/trustx.cfg >> ${WORKDIR}/defconfig
}

addtask do_preconfigure after do_patch before do_configure
