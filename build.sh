#!/bin/sh

set -e

topdir=$PWD

export ARCH=arm

help()
{
    echo "usage:"
    echo "       build.sh <option>"
    echo "example:"
    echo "        build.sh -all"
    echo "option:"
    echo "-all             compile the uboot, kernel and android"
    echo "-uboot           just compile uboot"
    echo "-kernel          just compile kernel"
    echo "-android         just compile android"
    exit 0
}
compile_uboot()
{
    cd $topdir/bootable/bootloader/uboot-imx

    export CROSS_COMPILE=$topdir/prebuilt/linux-x86/toolchain/arm-eabi-4.4.0/bin/arm-eabi-

    set +e 
    make distclean
    set -e
    make mx53_smd_android_config
    make 
    echo "build u-boot successful !!!--------------------------"
}

compile_kernel()
{
    cd $topdir/kernel_imx

    export CROSS_COMPILE=$topdir/prebuilt/linux-x86/toolchain/arm-eabi-4.4.3/bin/arm-eabi-
    PATH=${topdir}/bootable/bootloader/uboot-imx/tools:$PATH
    make uImage

    echo "build kernel successful !!!------------------------"
}

compile_android()
{
    cd $topdir

    export CROSS_COMPILE=$topdir/prebuilt/linux-x86/toolchain/arm-eabi-4.4.3/bin/arm-eabi- 

#    $SOURCE build/envsetup.sh 
    
    $LUNCH <<EOF
9
EOF

    make -j4

    echo "build android successful !!! -----------------------" 
    
    cd ${topdir}/out/target/product/imx53_smd
    
    ${topdir}/bootable/bootloader/uboot-imx/tools/mkimage -A arm -O linux -T ramdisk -C none -a 0x70308000 -n "Android Root Filesystem" -d ./ramdisk.img ./uramdisk.img

    echo "mkimage the ramdisk.img to uramdisk.img"
}

# --------------- main ---------------- #
if [ $# -lt 1 ]; then
    help
fi
c_uboot="no"
c_kernel="no"
c_android="no"

case "$1" in
-all)
    c_uboot="yes"
    c_kernel="yes"
    c_android="yes" ;;
-uboot)
    c_uboot="yes" ;;
-kernel)
    c_kernel="yes" ;;
-android)
    c_android="yes" ;;
*)
    help
esac

if [ $c_uboot = "yes" ]; then
    compile_uboot
fi

if [ $c_kernel = "yes" ]; then
    compile_kernel
fi

if [ $c_android = "yes" ]; then
    compile_android
fi



echo "build end"
