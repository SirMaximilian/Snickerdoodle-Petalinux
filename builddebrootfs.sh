
mkdir -p debrootfs/
rootfs=`pwd`/debrootfs/
echo $rootfs
#sudo qemu-debootstrap --arch=armhf --include=build-essential,autotools-dev,git,sudo,net-tools,python3,nfs-common,openssh-server,tcpdump bookworm images/linux/debrootfs http://ftp.us.debian.org/debian
debootstrap --verbose --foreign --arch armhf trixie $rootfs http://deb.debian.org/debian/
#debootstrap --verbose --foreign --arch armhf trixie debrootfs/ http://deb.debian.org/debian/

cp /usr/bin/qemu-arm-static $rootfs/usr/bin/

LANG=C chroot $rootfs/ /debootstrap/debootstrap --second-stage

# Configure filesystem

# Set up FSTAB
cat > $rootfs/etc/fstab << "EOF"
# Default snickerdoodle File System Table
# <file system>		<mount>		<type>		<options>	<dump>	<pass>
/dev/mmcblk0p1		/boot		vfat		defaults	0	0
/dev/mmcblk0p2		/		ext4		defaults	0	0
configfs		/config		configfs	defaults	0	0
tmpfs			/tmp		tmpfs		defaults	0	0

EOF

# Set the hostname
cat > $rootfs/etc/hostname << "EOF"
snickerdoodle
EOF

# Configure packages

cat > $rootfs/etc/apt/sources.list << "EOF"
deb http://deb.debian.org/debian trixie main non-free-firmware
#deb-src http://deb.debian.org/debian trixie main non-free-firmware

deb http://deb.debian.org/debian-security/ trixie-security main non-free-firmware
#deb-src http://deb.debian.org/debian-security/ trixie-security main non-free-firmware

deb http://deb.debian.org/debian trixie-updates main non-free-firmware
#deb-src http://deb.debian.org/debian trixie-updates main non-free-firmware

EOF

# Set up mount points
mount -t proc proc $rootfs/proc
mount -o bind /dev $rootfs/dev
mount -o bind /dev/pts $rootfs/dev/pts

# Install packages

packages="ethtool i2c-tools openssh-server openssl autotools-dev nfs-common tcpdump \
iw wpasupplicant hostapd isc-dhcp-server isc-dhcp-client build-essential bison ntp cmake \
flex python3 python3-dev python3-pip python3-venv iperf3 htop usbutils xterm parted net-tools \
netplan.io firmware-ti-connectivity zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev \
libreadline-dev libffi-dev libsqlite3-dev wget"

cat > $rootfs/third-stage << EOF
#!/bin/bash

#DEBIAN_FRONTEND=noninteractive
apt -y update && apt upgrade -y
apt -y install git-core binutils ca-certificates initramfs-tools u-boot-tools
apt -y install locales console-common less nano git sudo manpages systemd
apt -y install $packages
apt -y autoremove


if [ ! -d ./py3env  ]; then
  python3 -m venv ./py3env
fi
source py3env/bin/activate
pip install --upgrade pip
pip install --upgrade setuptools wheel
python3 -m pip install --extra-index-url=https://wpilib.jfrog.io/artifactory/api/pypi/wpilib-python-release-2024/simple robotpy

# Add default user
useradd -m -s "/bin/bash" -G sudo -U -p $(openssl passwd -6 tasker) tasker
#expire user password --naw actully
#passwd -e tasker
echo tasker:tasker | chpasswd -c SHA512
echo root:root | chpasswd -c SHA512

rm -f /third-stage

EOF

chmod +x $rootfs/third-stage
LANG=C chroot $rootfs /third-stage

umount $rootfs/dev/pts
umount $rootfs/dev
umount $rootfs/proc

# network config 

cat > $rootfs/etc/hosts << "EOF"
127.0.0.1	localhost snickerdoodle
::1		localhost ip6-localhost ip6-loopback
fe00::0		ip6-localnet
ff00::0		ip6-mcastprefix
ff02::1		ip6-allnodes
ff02::2		ip6-allrouters

EOF

cat > $rootfs/etc/resolv.conf << "EOF"
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF

cat > $rootfs/etc/wpa_supplicant.conf << "EOF"
ctrl_interface=/run/wpa_supplicant GROUP=netdev
ctrl_interface_group=0
update_config=1
country=US
# network={
#     ssid="null"
#     scan_ssid=1
#     key_mgmt=WPA-PSK
#     psk="null"
#        }
EOF

chmod 0600 $rootfs/etc/wpa_supplicant.conf

# wifi

cat > $rootfs/etc/modules << "EOF"
wl18xx
wlcore_sdio
wlcore
mac80211
libarc4
cfg80211
EOF

cat > $rootfs/etc/hostapd/hostapd.conf << "EOF"

interface=wlan1
driver=nl80211
logger_syslog=-1
logger_syslog_level=2
logger_stdout=-1
logger_stdout_level=2
ctrl_interface=/var/run/hostapd
ssid=snickerdoodle-ap
country_code=US
ieee80211d=1
ieee80211h=1
hw_mode=g
channel=11
beacon_int=100
dtim_period=2
max_num_sta=10
supported_rates=10 20 55 110 60 90 120 180 240 360 480 540
basic_rates=10 20 55 110 60 120 240
preamble=1
macaddr_acl=0
auth_algs=3
ignore_broadcast_ssid=0
tx_queue_data3_aifs=7
tx_queue_data3_cwmin=15
tx_queue_data3_cwmax=1023
tx_queue_data3_burst=0
tx_queue_data2_aifs=3
tx_queue_data2_cwmin=15
tx_queue_data2_cwmax=63
tx_queue_data2_burst=0
tx_queue_data1_aifs=1
tx_queue_data1_cwmin=7
tx_queue_data1_cwmax=15
tx_queue_data1_burst=3.0
tx_queue_data0_aifs=1
tx_queue_data0_cwmin=3
tx_queue_data0_cwmax=7
tx_queue_data0_burst=1.5
wme_enabled=1
uapsd_advertisement_enabled=1
wme_ac_bk_cwmin=4
wme_ac_bk_cwmax=10
wme_ac_bk_aifs=7
wme_ac_bk_txop_limit=0
wme_ac_bk_acm=0
wme_ac_be_aifs=3
wme_ac_be_cwmin=4
wme_ac_be_cwmax=10
wme_ac_be_txop_limit=0
wme_ac_be_acm=0
wme_ac_vi_aifs=2
wme_ac_vi_cwmin=3
wme_ac_vi_cwmax=4
wme_ac_vi_txop_limit=94
wme_ac_vi_acm=0
wme_ac_vo_aifs=2
wme_ac_vo_cwmin=2
wme_ac_vo_cwmax=3
wme_ac_vo_txop_limit=47
wme_ac_vo_acm=0
ap_max_inactivity=10000
disassoc_low_ack=1
ieee80211n=1
ht_capab=[SHORT-GI-20][GF]
wep_rekey_period=0
eap_server=1
own_ip_addr=127.0.0.1
wpa=2
wpa_passphrase=snickerdoodle
wpa_key_mgmt=WPA-PSK
wpa_pairwise=CCMP
wpa_group_rekey=0
wpa_gmk_rekey=0
wpa_ptk_rekey=0
ap_table_max_size=255
ap_table_expiration_time=60
wps_state=2
ap_setup_locked=1
device_name=snickerdoodle
manufacturer=krtkl
model_name=TI_connectivity_module
model_number=wl18xx
config_methods=virtual_display virtual_push_button keypad

EOF

chmod 600 $rootfs/etc/hostapd/hostapd.conf

cat > $rootfs/etc/dhcp/dhcpd.conf << "EOF"
#
# Configuration file for ISC dhcpd for Debian
#

ddns-update-style none;
log-facility local7;

subnet 10.0.110.0 netmask 255.255.255.0 {
	range 10.0.110.10 10.0.110.100;
	option routers 10.0.110.2;
	option broadcast-address 10.0.110.255;
	option domain-name		"local";
	default-lease-time		600;
	max-lease-time			7200;
}

EOF

chmod 600 $rootfs/etc/dhcp/dhcpd.conf

sed -i -e 's/^\(INTERFACESv4=\).*/INTERFACES=\"wlan1\"/' $rootfs/etc/default/isc-dhcp-server

mkdir -p $rootfs/etc/snickerdoodle/accesspoint

# Add script to bringup the wireless access pointt
cat > $rootfs/etc/snickerdoodle/accesspoint/wlan.sh << "EOF"
#!/bin/sh

IFACE=wlan1
HOSTAPD_CONF=/etc/hostapd/hostapd.conf

init_accesspoint () {
        echo 1 > /proc/sys/net/ipv4/ip_forward

        if [ ! -d /sys/class/net/$IFACE ]; then
                iw phy `ls /sys/class/ieee80211/` interface add $IFACE type managed
        fi

        HWID=`sed '{s/://g; s/.*\([0-9a-fA-F]\{6\}$\)/\1/}' /sys/class/net/$IFACE/address`
        DEFAULT_SSID=`hostname`-$HWID

        if [ -z $(grep -e "^ssid *=.*" $HOSTAPD_CONF) ]; then
                if [ -n $(grep -e "^#ssid *=.*" $HOSTAPD_CONF) ]; then
                        sed -ie "s/^#\(ssid *= *\).*$/\1$DEFAULT_SSID/g" $HOSTAPD_CONF
                fi
        fi
}

init_accesspoint
exit 0

EOF

chmod 755 $rootfs/etc/snickerdoodle/accesspoint/wlan.sh

cat > $rootfs/etc/netplan/98_wifi.yaml <<EOF
network:
  version: 2
  renderer: networkd
  wifis:
    wlan0:
      dhcp4: yes
      access-points:
         "xxx":
            password: "xxx"
EOF

cat > $rootfs/etc/netplan/99_config.yaml << "EOF"
network:
  version: 2
  renderer: networkd
  ethernets:
    wlan1:
      dhcp4: no
      addresses:
        - 10.0.110.2/24
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]

EOF

cat > $rootfs/etc/netplan/97_eth0.yaml << "EOF"
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: true
EOF

cat > $rootfs/etc/netplan/97_eth1.yaml << "EOF"
network:
  version: 2
  renderer: networkd
  ethernets:
    eth1:
      dhcp4: true
EOF

# setup services

cat > $rootfs/usr/local/bin/resizerootfs.sh<< "EOF"
#!/usr/bin/env bash
set -e
rootpart="/dev/$(lsblk -l -o NAME,MOUNTPOINT | grep '/' | awk '{print $1}')"
rootdevice="/dev/$(lsblk -no pkname "$rootpart")"
#rootdevice="/dev/$(lsblk -no pkname "/dev/$(lsblk -l -o NAME,MOUNTPOINT | grep '/' | awk '{print $1}')")"
partprobe "$rootdevice"
echo ", +" | sfdisk -f -N 1 "$rootdevice"
partprobe "$rootdevice"
resize2fs "$rootpart"
partprobe "$rootdevice"

EOF

cat > $rootfs/lib/systemd/system/resizerootfs.service<< "EOF"
[Unit]
Description=Resize the rootfs
Before=local-fs-pre.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/resizerootfs.sh
RemainAfterExit=yes

[Install]
RequiredBy=local-fs-pre.target
EOF

### setup wlan accesspoint

cat > $rootfs/usr/lib/systemd/system/setup_wlan.service << "EOF"
[Unit]
Description=configure wlan1 interface
After=network.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/etc/snickerdoodle/accesspoint/wlan.sh

[Install]
WantedBy=multi-user.target
EOF

chmod 644 $rootfs/usr/lib/systemd/system/setup_wlan.service

ln -s /usr/lib/systemd/system/setup_wlan.service $rootfs/etc/systemd/system/multi-user.target.wants/setup_wlan.service

# Perform cleanup on the filesystem

cat > $rootfs/cleanup << "EOF"
#!/bin/bash

ln -s /dev/null /etc/systemd/network/99-default.link
#systemctl enable resizerootfs.service

rm -rf /root/.bash_history
apt update
apt clean
rm -f /cleanup
rm -f /usr/bin/qemu*

EOF

chmod +x $rootfs/cleanup
LANG=C chroot $rootfs /cleanup

# copy boot files
#cp images/linux/BOOT.BIN images/linux/image.ub images/linux/boot.scr images/linux/system.bit images/linux/system.dtb images/linux/uImage $rootfs/boot/