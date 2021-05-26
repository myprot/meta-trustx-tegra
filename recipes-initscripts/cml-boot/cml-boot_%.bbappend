## Remove redirection of consolre output to enable automatic start of CML on NXP devices

do_install_prepend() {
	sed -i '/exec > \/dev\/$LOGTTY*/c\#exec > \/dev\/$LOGTTY' ${WORKDIR}/cml-boot-script.stub
	sed -i '/exec 2>&1*/c\#exec 2>&1' ${WORKDIR}/cml-boot-script.stub
}
