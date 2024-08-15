FILESEXTRAPATHS:prepend := "${THISDIR}/linux-firmware:"

SRC_URI += "file://wl18xx-conf-default.bin \
            file://wl18xx-fw-4.bin"

do_install:append() {
        install -d 0644 ${D}${base_libdir}/firmware/ti-connectivity/
        install -m 0644 ${WORKDIR}/wl18xx-conf-default.bin ${D}${base_libdir}/firmware/ti-connectivity/wl18xx-conf.bin
        install -m 0644 ${WORKDIR}/wl18xx-fw-4.bin ${D}${base_libdir}/firmware/ti-connectivity/wl18xx-fw-4.bin
}