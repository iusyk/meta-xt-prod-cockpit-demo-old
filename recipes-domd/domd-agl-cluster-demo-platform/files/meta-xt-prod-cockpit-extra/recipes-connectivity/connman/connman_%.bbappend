FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

ALTERNATIVE_TARGET[resolv-conf] = "${@bb.utils.contains('DISTRO_FEATURES','systemd','${sysconfdir}/resolv-conf.systemd','',d)}"

