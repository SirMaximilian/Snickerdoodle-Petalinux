petalinux-package --boot --format BIN --fpga images/linux/system.bit --u-boot images/linux/u-boot-dtb.elf --force
#petalinux-package --boot --format BIN --fpga images/linux/system.bit --u-boot --kernel --offset 0x1080000 --force
#petalinux-package --boot --u-boot images/linux/u-boot.elf --dtb images/linux/system.dtb --fsbl images/linux/zynq_fsbl.elf --kernel images/linux/image.ub --offset 0x1080000 --boot-script images/linux/boot.scr --format MCS
petalinux-package --wic --wks rootfs.wks --outdir /home/tasker/Share --extra-bootfiles "image.ub system.dtb system.bit boot.scr uImage"