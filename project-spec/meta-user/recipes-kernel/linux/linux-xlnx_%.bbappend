FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " file://bsp.cfg"
KERNEL_FEATURES:append = " bsp.cfg"
SRC_URI += "file://user_2024-04-27-03-51-00.cfg \
            file://user_2024-07-18-10-40-00.cfg \
            "

