thisDir=`pwd`
set -e
petalinux-package --boot --format BIN --fpga images/linux/system.bit --u-boot images/linux/u-boot-dtb.elf --force
rm -f debrootfs.tar.gz
sudo rm -f debrootfs/boot/*
sudo cp images/linux/BOOT.BIN images/linux/image.ub images/linux/boot.scr images/linux/system.bit images/linux/system.dtb images/linux/uImage debrootfs/boot/
cd debrootfs/
sudo  tar -zcf ../debrootfs.tar.gz . && cd -
petalinux-package wic --wks rootfs.wks --rootfs-file debrootfs.tar.gz --outdir $thisDir --extra-bootfiles "image.ub system.dtb system.bit boot.scr uImage"