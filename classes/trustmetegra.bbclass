inherit image_types
inherit kernel-artifact-names

#
# Create an partitioned trustme image that can be dd'ed to the boot medium
#

TEST_CERT_DIR = "${TOPDIR}/test_certificates"
SECURE_BOOT_SIGNING_KEY = "${TEST_CERT_DIR}/ssig_subca.key"
SECURE_BOOT_SIGNING_CERT = "${TEST_CERT_DIR}/ssig_subca.cert"

TRUSTME_IMAGE_TMP="${DEPLOY_DIR_IMAGE}/tmp_trustmeimage"
TRUSTME_TARGET_ALIGN="4096"
TRUSTME_TARGET_SECTOR_SIZE="4096"
TRUSTME_SECTOR_SIZE="4096"
TRUSTME_PARTTABLE_TYPE?="gpt"

TRUSTME_IMAGE_OUT="${DEPLOY_DIR_IMAGE}/trustme_image"

TRUSTME_IMAGE="${TRUSTME_IMAGE_OUT}/trustmeimage.img"
TRUSTME_DATAPART_EXTRA_FACTOR="1.2"
TRUSTME_DATAPART_FS="ext4"
TRUSTME_ROOTFS_ALIGN="4096"

TRUSTME_DEFAULTCONFIG?="trustx-core.conf"

TRUSTME_GENERIC_DEPENDS = " \
    parted-native:do_populate_sysroot \
    mtools-native:do_populate_sysroot \
    dosfstools-native:do_populate_sysroot \
    gptfdisk-native:do_populate_sysroot \
    trustx-cml-initramfs:do_image_complete \
    virtual/kernel:do_deploy \
"

do_image_trustmetegra[depends] = " \
"


do_image_trustmetegra[depends] += " ${TRUSTME_GENERIC_DEPENDS} "

do_tegra_bootpart () {
}


IMAGE_CMD_trustmetegra () {
	bbnote  "Using standard trustme partition"
	do_build_trustmeimage
}

do_build_trustmeimage () {

	if [ -z "${TOPDIR}" ];then
		bbfatal_log "Cannot get bitbake variable \"TOPDIR\""
		exit 1
	fi

	if [ -z "${DEPLOY_DIR_IMAGE}" ];then
		bbfatal_log "Cannot get bitbake variable \"DEPLOY_DIR_IMAGE\""
		exit 1
	fi

	if [ -z "${DEPLOY_DIR_IPK}" ];then
		bbfatal_log "Cannot get bitbake variable \"DEPLOY_DIR_IPK\""
		exit 1
	fi


	if [ -z "${MACHINE_ARCH}" ];then
		bbfatal_log "Cannot get bitbake variable \"MACHINE_ARCH\""
		exit 1
	fi

	if [ -z "${WORKDIR}" ];then
		bbfatal_log "Cannot get bitbake variable \"WORKDIR\""
		exit 1
	fi

	if [ -z "${S}" ];then
		bbfatal_log "Cannot get bitbake variable \"TRUSTME_HARDWARE\""
		exit 1
	fi

	if [ -z "${PREFERRED_PROVIDER_virtual/kernel}" ];then
		bbfatal_log "Cannot get bitbake variable \"PREFERRED_PROVIDER_virtual/kernel\""
		exit 1
	fi

	if [ -z "${MACHINE}" ];then
		bbfatal_log "Cannot get bitbake variable \"MACHINE\""
		exit 1
	fi

	if [ -z "${DISTRO}" ];then
		bbfatal_log "Cannot get bitbake variable \"DISTRO\""
		exit 1
	fi

	if [ -z "${TRUSTME_IMAGE_OUT}" ];then
		bbfatal_log "Cannot get bitbake variable \"TRUSTME_IMAGE_OUT\""
		exit 1
	fi

	if [ -z "${TRUSTME_IMAGE_TMP}" ];then
		bbfatal_log "Cannot get bitbake variable \"TRUSTME_IMAGE_TMP\""
		exit 1
	fi

	if [ -z "${TRUSTME_CONTAINER_ARCH_${MACHINE}}" ];then
		bbfatal_log "Cannot get bitbake variable \"TRUSTME_CONTAINER_ARCH_${MACHINE}\""
		exit 1
	fi



	rm -fr ${TRUSTME_IMAGE_TMP}
	rm -f "${TRUSTME_IMAGE}"

	machine=$(echo "${MACHINE}" | tr "-" "_")

	bbnote "Starting to create trustme image"
	# create temporary directories
	install -d "${TRUSTME_IMAGE_OUT}"
	tmp_modules="${TRUSTME_IMAGE_TMP}/tmp_modules"
	tmp_firmware="${TRUSTME_IMAGE_TMP}/tmp_firmware"
	tmp_datapart="${TRUSTME_IMAGE_TMP}/tmp_data"
	rootfs_datadir="${tmp_datapart}/userdata/"
	tmpdir="${TOPDIR}/tmp_container"
	trustme_fsdir="${TRUSTME_IMAGE_TMP}/filesystems"
	trustme_bootfs="$trustme_fsdir/trustme_bootfs"
	trustme_datafs="$trustme_fsdir/trustme_datafs"

	install -d "${TRUSTME_IMAGE_TMP}"
	rm -fr "${rootfs_datadir}"
	install -d "${rootfs_datadir}"
	rm -fr "${trustme_fsdir}"
	install -d "${trustme_fsdir}"
	rm -fr "${tmp_modules}/"
	install -d "${tmp_modules}/"
	rm -fr "${tmp_firmware}/"
	install -d "${tmp_firmware}/"

	rm -fr "${tmp_firmware}/"
	install -d "${tmp_firmware}/"

	install -d "${rootfs_datadir}/cml/tokens"
	install -d "${rootfs_datadir}/cml/containers_templates"

	# define file locations
	containerarch="${TRUSTME_CONTAINER_ARCH_${MACHINE}}"
	deploy_dir_container="${tmpdir}/deploy/images/$(echo $containerarch | tr "_" "-")"

	src="${TOPDIR}/../trustme/build/"
	config_creator_dir="${src}/config_creator"
	proto_file_dir="${WORKDIR}/cml/daemon"
	provisioning_dir="${src}/device_provisioning"
	enrollment_dir="${provisioning_dir}/oss_enrollment"
	test_cert_dir="${TOPDIR}/test_certificates"
	cfg_overlay_dir="${src}/config_overlay"

	if ! [ -d "${test_cert_dir}" ];then
		bbfatal_log "Test PKI not generated at ${test_cert_dir}\nIs trustx-cml-userdata built?"
		exit 1
	fi

	# copy files to temp data directory
	bbnote "Preparing files for data partition"

	cp -f "${test_cert_dir}/ssig_rootca.cert" "${rootfs_datadir}/cml/tokens/"
	mkdir -p "${rootfs_datadir}/cml/operatingsystems/"
	mkdir -p "${rootfs_datadir}/cml/containers/"

	if [ -d "${TOPDIR}/../custom_containers" ];then # custom container provided in ${TOPDIR}/../custom_container
		bbnote "Installing custom container and configs to image: ${TOPDIR}/../custom_containers"
		cp -far "${TOPDIR}/../custom_containers/00000000-0000-0000-0000-000000000000.conf" "${rootfs_datadir}/cml/containers_templates/"
		find "${TOPDIR}/../custom_containers/" -name '*os*' -exec cp -afr {} "${rootfs_datadir}/cml/operatingsystems" \;
		cp -f "${TOPDIR}/../custom_containers/device.conf" "${rootfs_datadir}/cml/"
	elif [ -d "${deploy_dir_container}/trustx-guests" ];then # container built in default location
		bbnote "Installing containers from default location ${deploy_dir_container}/trustx-guests"
		cp -far "${deploy_dir_container}/trustx-configs/container/." "${rootfs_datadir}/cml/containers_templates/"
		cp -afr "${deploy_dir_container}/trustx-guests/." "${rootfs_datadir}/cml/operatingsystems"
		cp -f "${deploy_dir_container}/trustx-configs/device.conf" "${rootfs_datadir}/cml/"
	else # no container provided
		bbwarn "It seems that no containers were built in directory ${deploy_dir_container}. You will have to provide at least c0 manually!"
		cp ${cfg_overlay_dir}/${TRUSTME_HARDWARE}/device.conf "${rootfs_datadir}/cml/"
	fi

	# sign container configs
	find "${rootfs_datadir}/cml/containers_templates" -name '*.conf' -exec bash \
		${enrollment_dir}/config_creator/sign_config.sh {} \
		${TEST_CERT_DIR}/ssig.key ${TEST_CERT_DIR}/ssig.cert \;

	# copy trustme files to image deploy dir
	cp -afr "${tmp_datapart}/." "${TRUSTME_IMAGE_OUT}/trustme_datapartition"


	datapart_size_targetblocks="$(du --block-size=${TRUSTME_TARGET_ALIGN} -s ${tmp_datapart} | awk '{print $1}')"
	datapart_size_targetblocks="$(python -c "from math import ceil; print(str(ceil($datapart_size_targetblocks + ($datapart_size_targetblocks * ${TRUSTME_DATAPART_EXTRA_FACTOR})))[:-2])")"
	datapart_size_bytes="$(expr $datapart_size_targetblocks '*' ${TRUSTME_TARGET_ALIGN})"
	datafolder_size="$(expr $datapart_size_targetblocks '*' ${TRUSTME_TARGET_ALIGN})"
	bbnote "Data files size: $datafolder_size bytes"

	##### create filesystems #####


	# creating data filesystem
	bbnote "Creating data filesystem ${trustme_datafs}"
	bbdebug 1 "dd'ing data fs: ${datapart_size_targetblocks} 4K blocks, $(expr ${datapart_size_targetblocks} '*' ${TRUSTME_TARGET_ALIGN}) bytes"
	dd if=/dev/zero of="$trustme_datafs" conv=notrunc,fsync iflag=sync oflag=sync bs=${TRUSTME_TARGET_ALIGN} count=$datapart_size_targetblocks
	/bin/sync
	bbdebug 1 "Creating ext4 fs of size ${datapart_size_targetblocks} blocks, ${datapart_size_bytes} bytes on file $trustme_datafs"
	mkfs.ext4 -b ${TRUSTME_TARGET_ALIGN} -d "$tmp_datapart" -L trustme "$trustme_datafs" "${datapart_size_targetblocks}"
	chmod 644 "$trustme_datafs"

	/bin/sync

	##### Create empty image and partition table #####
	dataimg_size_targetblocks="${datapart_size_targetblocks}"
	dataimg_size_bytes="$(expr $dataimg_size_targetblocks '*' ${TRUSTME_TARGET_ALIGN})"

	bbdebug 1 "Filesystem sizes:\ndataimg_size_targetblocks $dataimg_size_targetblocks\ndataimg_size_bytes $dataimg_size_bytes"
	##### calc start/end of partitions #####
	# cals start/end of data partition
	start_datapart="$(expr 34 '*' ${TRUSTME_TARGET_SECTOR_SIZE})"
	start_datapart="$(expr $start_datapart + '(' $start_datapart '%' ${TRUSTME_TARGET_ALIGN} ')' )"
	start_datapart_targetblocks="$(expr $start_datapart '/' ${TRUSTME_TARGET_ALIGN})"
	end_datapart="$(expr $start_datapart + $datapart_size_bytes)"

	end_datapart_target_blocks="$(expr $start_datapart + $datapart_size_bytes)"


	img_size_targetblocks="$(expr '(' $end_datapart + '(' $end_datapart '%' ${TRUSTME_TARGET_ALIGN} ')' + 34 '*' ${TRUSTME_TARGET_ALIGN} + 10000 '*' ${TRUSTME_TARGET_ALIGN} ')' '/' ${TRUSTME_TARGET_ALIGN})"
	img_size="$(expr $img_size_targetblocks '*' ${TRUSTME_TARGET_ALIGN})"


	##### Create partitions #####
	bbdebug 1 "Creating empty image file"

	rm -f ${TRUSTME_IMAGE}
	dd if=/dev/zero of=${TRUSTME_IMAGE} bs=${TRUSTME_TARGET_ALIGN} count=$img_size_targetblocks conv=notrunc,fsync iflag=sync oflag=sync status=progress
	/bin/sync
	sleep 2
	tmp_img_size="$(du --block-size=1 ${TRUSTME_IMAGE})"
	if ! [ "$tmp_img_size"="$img_size" ];then
		bbfatal_log "Image size should be $img_size but is $tmp_img_size. Aborting..."
	else
		bbnote "Sucessfully verified size of ${TRUSTME_IMAGE}"
	fi

	bbnote "Creating partition table:"
	bbnote  "Building image using ${TRUSTME_PARTTABLE_TYPE} partition table"
	parted -s "${TRUSTME_IMAGE}" unit B --align none mklabel ${TRUSTME_PARTTABLE_TYPE}
	bbnote  "created label"

	if [ "${TRUSTME_PARTTABLE_TYPE}" = "gpt" ];then
		bbnote  "Moving second header on ${TRUSTME_PARTTABLE_TYPE} image"
		sgdisk --move-second-header "${TRUSTME_IMAGE}"
	fi

	# Create data partition
	parted -s ${TRUSTME_IMAGE} unit B --align none mkpart primary "${TRUSTME_DATAPART_FS}" "${start_datapart}B" "${end_datapart}B"
	sync
	partprobe
	bbnote "Created data partition"

	if [ "${TRUSTME_PARTTABLE_TYPE}" = "gpt" ];then
		
		parted -s ${TRUSTME_IMAGE} name 1 trustme
		parted -s ${TRUSTME_IMAGE} set 1 legacy_boot off
		parted -s ${TRUSTME_IMAGE} set 1 msftdata  off
		parted -s ${TRUSTME_IMAGE} set 1 boot off
		parted -s ${TRUSTME_IMAGE} set 1 esp off
		sync
		partprobe

		bbnote "Done setting Set partiion names and flags"
	fi


	bbnote "Copying filesystems to partitions"
		bbnote "Copying data filesystem to partition"
	bbdebug 1 "img_size(planned): ${img_size}, img_size (real): $(du --block-size=1 ${TRUSTME_IMAGE})\nimg_size_targetblocks: ${img_size_targetblocks}, start_datapart=${start_datapart}, end_datapart: ${end_datapart}"

	# TODO host tool
	/bin/sync
	dd if=${trustme_datafs} of=${TRUSTME_IMAGE} bs=${TRUSTME_TARGET_ALIGN} count=${dataimg_size_targetblocks} seek=${start_datapart_targetblocks} conv=notrunc,fsync iflag=sync oflag=sync status=progress

	partlayout="$(parted ${TRUSTME_IMAGE} unit B --align none print 2>&1)"
	bbnote "Final partition layout:\n${partlayout}"

	checkfs="$(cmp ${trustme_datafs} ${TRUSTME_IMAGE} --bytes=${dataimg_size_bytes} --ignore-initial=0:$(expr ${start_datapart_targetblocks} '*' ${TRUSTME_TARGET_ALIGN}))"

	if [ "${checkfs}"="" ];then
		bbnote "Sucessfully verified integrity of data filesystem"
	else
		bbfatal_log "Failed to verify integrity of data filesystem. Aborting..."
	fi

	bbnote "Successfully created trustme image at ${TRUSTME_IMAGE}"
}
