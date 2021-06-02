FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://0001-daemon-c_vol-disable-ovl-metacopy-paramter.patch \
            file://0001-disable-integrity-mapping.patch \
            "
