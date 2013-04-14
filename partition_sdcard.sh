#!/bin/sh
# Author Netfire.liang

set -e

debug="no"
#debug="yes"

topdir=$PWD

help()
{
	echo "usage:"
	echo "        partition.sh <device> <option>"
	echo "example:" 
	echo "        partition.sh /dev/mmcblk0 -all"
	echo "option:"
	echo "-all           partition and format and copy data to the disk"
	echo "-p             just partition the disk"
	echo "-f             just format the disk"
	echo "-c             just copy data to the disk"
	exit 0
}

get_disk_space()
{
	disk_space=`sudo fdisk -l $1 | grep -w "Disk" | awk '{print $3}' | sed '2d'`
	echo "$disk_space"
}

partition_disk()
{
sudo fdisk -c -u $disk << EOF
d
1
d
2
d
3
d

n #partition 1 3G space
p
1
+10M
+3000M
n #partiton 2 200M space
p
2
+3010M
+200M
n #partiton 3 extended 300M space
e
3
+3210M
+300M
n #partition 4 20M
p
+3510M
+20M
n # extended space 5 250M

+250M
n


p #print the partition table
${write_or_not}
EOF
sync
echo "partition disk finished."
}

format_disk()
{
	echo "format the disk"
    set +e
    sudo umount ${2}1
    sudo umount ${2}2
    sudo umount ${2}3
    sudo umount ${2}4
    sudo umount ${2}5
    sudo umount ${2}6
    set -e
	sudo mkfs.vfat ${2}1
	sudo mkfs.ext4 ${2}2 -O ^extent -L system
	sudo mkfs.ext4 ${2}4 -O ^extent -L recovery
	sudo mkfs.ext4 ${2}5 -O ^extent -L data
	sudo mkfs.ext4 ${2}6 -O ^extent -L cache
	sudo sync
    echo "format disk finished."
}

copy_data_to_disk()
{
    cd ${topdir}/out/target/product/imx53_smd

    ${topdir}/bootable/bootloader/uboot-imx/tools/mkimage -A arm -O linux -T ramdisk -C none -a 0x70308000 -n "Android Root Filesystem" -d ./ramdisk.img ./uramdisk.img

    echo "mkimage the ramdisk.img to uramdisk.img"

	echo "copying files to disk"
    echo "copying u-boot.bin "
	sudo dd if=${topdir}/bootable/bootloader/uboot-imx/u-boot.bin of=$1 bs=1K skip=1 seek=1; sync
	echo "copying uImage"
    sudo dd if=${topdir}/kernel_imx/arch/arm/boot/uImage of=$1 bs=1M seek=1; sync
	echo "copying uramdisk.img"
    sudo dd if=${topdir}/out/target/product/imx53_smd/uramdisk.img of=$1 bs=1M seek=6; sync
	echo "copying system.img"
    sudo dd if=${topdir}/out/target/product/imx53_smd/system.img of=${2}2; sync
	echo "copying recovery.img"
    sudo dd if=${topdir}/out/target/product/imx53_smd/recovery.img of=${2}4; sync
    echo "copy data finished."
}

#--------- main ----------
if [ $# -lt 2 ]; then
	help
fi

write_or_not="q"
if [ $debug = "yes" ]; then
write_or_not="q"
else
write_or_not="w"
fi

disk=$1
diskp=""

if [ $disk = "/dev/mmcblk0" ]; then
	echo "disk is ${disk}"
	diskp="${disk}p"
	echo $disk
fi

p_d="no"
f_d="no"
c_d="no"

case "$2" in
-all) 
	p_d="yes" 
	f_d="yes" 
	c_d="yes" ;;
-p) 
	p_d="yes" ;;
-c) 
	c_d="yes" ;;
-f)
	f_d="yes" ;;
*) 
	help
esac

get_disk_space $disk

if [ $p_d = "yes" ]; then
	partition_disk $disk $diskp
fi

if [ "${debug}" != "yes" ]; then

	if [ $f_d = "yes" ]; then
		format_disk $disk $diskp
	fi

	if [ $c_d = "yes" ]; then
		copy_data_to_disk $disk $diskp
	fi

fi
echo "all done."
