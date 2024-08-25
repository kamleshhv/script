#!/usr/bin/env sh
#
# GNU General Public License v3.0
# Copyright (C) 2023 MoChenYa mochenya20070702@gmail.com
#

WORKDIR="$(pwd)"

# ZyClang
mkdir clang; cd clang;curl -LO "https://raw.githubusercontent.com/Neutron-Toolchains/antman/main/antman";
chmod +x antman; ./antman -S=05012024; ./antman --patch=glibc;sed -i '/CLANG_EXTRA_FLAGS += --hip-path=\/dev\/null/d'
ZYCLANG_DIR="$WORKDIR/clang/bin"

# Kernel Source
KERNEL_GIT="https://github.com/kamleshhv/kernel_xiaomi_sweet"
KERNEL_BRANCHE="14"
KERNEL_DIR="$WORKDIR/Perf"

# Anykernel3
ANYKERNEL3_GIT="https://github.com/pure-soul-kk/AnyKernel3"
ANYKERNEL3_BRANCHE="master"

# Build
DEVICES_CODE="sweet"
DEVICE_DEFCONFIG="vendor/sweet_defconfig"
DEVICE_DEFCONFIG_FILE="$KERNEL_DIR/arch/arm64/configs/$DEVICE_DEFCONFIG"
IMAGE="$KERNEL_DIR/out/arch/arm64/boot/Image.gz"
DTB="$KERNEL_DIR/out/arch/arm64/boot/dtb.img"
DTBO="$KERNEL_DIR/out/arch/arm64/boot/dtbo.img"

export KBUILD_BUILD_USER=krishna
export KBUILD_BUILD_HOST=GitHubCI

msg() {
	echo
	echo -e "\e[1;32m$*\e[0m"
	echo
}

cd $WORKDIR

# CLANG LLVM VERSIONS
CLANG_VERSION="$($ZYCLANG_DIR/clang --version | head -n 1)"
LLD_VERSION="$($ZYCLANG_DIR/ld.lld --version | head -n 1)"

msg " • 🌸 Cloning Kernel Source 🌸 "
rm -rf $KERNEL_DIR
git clone --depth=1 $KERNEL_GIT -b $KERNEL_BRANCHE $KERNEL_DIR
cd $KERNEL_DIR

# BUILD KERNEL
msg " • 🌸 Started Compilation 🌸 "

args="PATH=$ZYCLANG_DIR:$PATH \
ARCH=arm64 \
SUBARCH=arm64 \
CROSS_COMPILE=aarch64-linux-gnu- \
CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
CC=clang \
NM=llvm-nm \
CXX=clang++ \
AR=llvm-ar \
LD=ld.lld \
STRIP=llvm-strip \
OBJDUMP=llvm-objdump \
OBJSIZE=llvm-size \
READELF=llvm-readelf \
HOSTAR=llvm-ar \
HOSTLD=ld.lld \
HOSTCC=clang \
HOSTCXX=clang++ \
LLVM=1 \
LLVM_IAS=1"

# LINUX KERNEL VERSION
make O=out $args $DEVICE_DEFCONFIG
KERNEL_VERSION=$(make O=out $args kernelversion | grep "4.14")
msg " • 🌸 LINUX KERNEL VERSION : $KERNEL_VERSION 🌸 "
make O=out $args -j"$(nproc --all)"

msg " • 🌸 Packing Kernel 🌸 "
cd $WORKDIR
rm -rf $WORKDIR/Anykernel3
git clone --depth=1 $ANYKERNEL3_GIT -b $ANYKERNEL3_BRANCHE $WORKDIR/Anykernel3
cd $WORKDIR/Anykernel3
cp $IMAGE .
cp $DTB $WORKDIR/Anykernel3/dtb
cp $DTBO .

# PACK FILE
time=$(TZ='Asia/Kolkata' date +"%Y-%m-%d %H:%M:%S")
asia_time=$(TZ='Asia/Kolkata' date +%Y%m%d%H)
ZIP_NAME="Strixx-$KERNEL_VERSION.zip"
find ./ * -exec touch -m -d "$time" {} \;
zip -r9 $ZIP_NAME *
mkdir -p $WORKDIR/out && cp *.zip $WORKDIR/out

cd $WORKDIR/out
msg "• 🌸 Done! 🌸 "
