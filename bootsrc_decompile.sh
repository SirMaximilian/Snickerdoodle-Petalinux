tail -c+73 < images/linux/boot.scr > images/linux/boot.txt
# recompile
# mkimage -c none -A arm -T script -d images/linux/boot.txt images/linux/boot.scr