
# Petalinux Snickerdoodle

base project for seting up snickerdoodle with basic newtork functionality
currently have wifi and ethernet1 working correctly. issues with ethernet0 rn

## Building

Currently have a debian root file system configured.
to use the debian fs first build the base Petalinux project then build the fs by running ./builddebrootfs.sh as root/sudo. To package the image run ./debfspackage.sh as non-root with petalinux utils sourced it wil ask for root where it is needed. Change output dir in debfspackage.sh to match desired path. and modify the wifi configs in builddebrootfs.sh, around line 284, to desired setting too.
