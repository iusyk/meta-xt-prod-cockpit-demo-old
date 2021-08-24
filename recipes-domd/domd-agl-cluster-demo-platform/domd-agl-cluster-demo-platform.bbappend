FILESEXTRAPATHS_prepend := "${THISDIR}/../../inc:"
FILESEXTRAPATHS_append := "${THISDIR}/files:"
do_patch[depends] += "domd-image-weston:do_patch"
do_unpack[depends] += "domd-image-weston:do_unpack"
do_sharemeta[depends] += "domd-image-weston:do_sharemeta"
do_unpack_xt_extras[depends] += "domd-image-weston:do_unpack_xt_extras"

###############################################################################
# extra layers and files to be put after Yocto's do_unpack into inner builder
###############################################################################
# these will be populated into the inner build system on do_unpack_xt_extras
# N.B. xt_shared_env.inc MUST be listed AFTER meta-xt-prod-extra
XT_QUIRK_UNPACK_SRC_URI += " \
     file://meta-xt-prod-cockpit-extra;subdir=repo \
"

SRC_URI_rcar_append = " \
    repo://github.com/xen-troops/manifests;protocol=https;branch=master;manifest=prod_cockpit_demo_src/domd.xml;scmdata=keep \
"

XT_QUIRK_PATCH_SRC_URI_append_h3ulcb-4x2g-kf = "\
    file://0001-kingfisher_output.cfg-remove-mode-off-for-HDMI-A-2.patch;patchdir=meta-agl \
    file://0001-connman-main.conf-add-can-lo-vif-xenbr-eth-in-black-.patch;patchdir=meta-agl \
    file://0001-hdmi-a-1-180.cfg-change-transform-at-0.patch;patchdir=meta-agl-cluster-demo \
    file://0001-aglsetup.sh-remove-external-from-the-path.patch;patchdir=meta-agl \
    file://0001-bblayers.conf.sample-bsp-folder-removing.patch;patchdir=meta-agl \
    file://0001-Remove-external-and-bsp-sub-folders.patch;patchdir=meta-agl \
    file://0001-h3ulcb-bblayers.conf.sample-remove-sub-directory-bsp.patch;patchdir=meta-xt-agl-base \
    file://0001-50_bblayers.conf.inc-remove-sub-directory-external.patch;patchdir=meta-agl \
"
# these layers will be added to bblayers.conf on do_configure
XT_QUIRK_BB_ADD_LAYER += "meta-xt-prod-cockpit-extra"
XT_QUIRK_BB_ADD_LAYER += "meta-xt-agl-base"
XT_QUIRK_BB_ADD_LAYER += "meta-xt-prod-extra"
XT_QUIRK_BB_ADD_LAYER += "meta-xt-prod-domx"

link_layers(){
     shared_root_fs="${@d.getVar('XT_SHARED_ROOTFS_DIR') or ''}"
     recipe_name="${@d.getVar('BPN') or ''}"
     repodir="${@d.getVar('B') or ''}"

     deploy_dependency ${shared_root_fs}/domd-image-weston ${repodir} 
}

python do_configure_prepend(){
    bb.build.exec_func("link_layers", d)
}

# Override revision of AGL auxiliary layers
# N.B. the revision to use must be aligned with Poky's version of AGL to be built with
BRANCH = "thud"

################################################################################
# Renesas R-Car
################################################################################
SRCREV_agl-repo = "icefish_9.0.2"
SRCREV_img-proprietary = "ef1aa566d74a11c4d2ae9592474030a706b4cf39"

GLES_VERSION_rcar = "1.11"

configure_versions_kingfisher() {
    local local_conf="${S}/build/conf/local.conf"

    cd ${S}
    #FIXME: patch ADAS: do not use network setup as we provide our own
    base_add_conf_value ${local_conf} BBMASK "meta-rcar-gen3-adas/recipes-core/systemd"
    # Remove development tools from the image
    base_add_conf_value ${local_conf} IMAGE_INSTALL_remove " strace eglibc-utils ldd rsync gdbserver dropbear opkg git subversion nano cmake vim"
    base_add_conf_value ${local_conf} DISTRO_FEATURES_remove " opencv-sdk"
    # Do not enable surroundview which cannot be used
    base_add_conf_value ${local_conf} DISTRO_FEATURES_remove " surroundview"
    base_update_conf_value ${local_conf} PACKAGECONFIG_remove_pn-libcxx "unwind"
    base_update_conf_value ${local_conf} DISTRO_FEATURES_append " pvcamera"

    # Remove the following if we use prebuilt EVA proprietary "graphics" packages
    if [ ! -z ${XT_RCAR_EVAPROPRIETARY_DIR} ];then
        base_update_conf_value ${local_conf} PACKAGECONFIG_remove_pn-cairo " egl glesv2"
    fi
}

python do_configure_append_h3ulcb-4x2g-kf() {
    bb.build.exec_func("configure_versions_kingfisher", d)
}

do_install_append () {
    local LAYERDIR=${TOPDIR}/../meta-xt-prod-cockpit-demo
    find ${LAYERDIR}/doc -iname "u-boot-env*" -exec cp -f {} ${DEPLOY_DIR}/domd-image-weston/images/${MACHINE}-xt \; || true
    if echo "${XT_GUESTS_INSTALL}" | grep -qi "domu";then
        find ${LAYERDIR}/doc -iname "mk_sdcard_image_domu.sh" -exec cp -f {} ${DEPLOY_DIR}/domd-image-weston/images/${MACHINE}-xt/mk_sdcard_image.sh \; \
        -exec cp -f {} ${DEPLOY_DIR}/mk_sdcard_image.sh \; || true
    else
        find ${LAYERDIR}/doc -iname "mk_sdcard_image.sh" -exec cp -f {} ${DEPLOY_DIR}/domd-image-weston/images/${MACHINE}-xt \; \
        -exec cp -f {} ${DEPLOY_DIR} \; || true
    fi
}
