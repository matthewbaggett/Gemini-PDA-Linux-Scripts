#!/bin/bash
echo "Checking for build dependencies..."
if [ ! -f /usr/bin/make ] || [ ! -f /usr/bin/gcc ] || [ ! -f /usr/bin/ncurses5-config ] || [ ! -f /usr/bin/bc ] || [ ! -f /usr/bin/rsync ]; then
    echo "Gotta install some thangs"
    sudo apt-get -qq update
    sudo apt-get -yqq install \
        make \
        gcc \
        libncurses5-dev \
        bc \
        rsync
else
    echo "Everything appears to be present..."
fi

# If a clean copy of 3.18 isn't present, get it
if [ ! -d kernel/clean ]; then
    git clone https://github.com/gemian/gemini-linux-kernel-3.18 kernel/clean
    git -C kernel/clean reset --hard bf7daa4
fi

# Get the compiler from github
if [[ ! -d kernel/aarch64-linux-android-4.9 ]]; then
    git clone https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 kernel/aarch64-linux-android-4.9 -b nougat-release --depth 1
fi

# Get MkBootImage
if [[ ! -d kernel/mkbootimg ]]; then
    git clone https://github.com/osm0sis/mkbootimg.git kernel/mkbootimg
fi

# Delete any previous copies
if [[ -d kernel/build ]]; then
    rm -Rf kernel/build;
fi
mkdir kernel/build;

# Delete any previous output...
if [[ -d kernel/out ]]; then
    rm -Rf kernel/out;
fi
mkdir kernel/out;

# Copy over a fresh copy of our clean 3.18 kernel
rsync -a --exclude='.git/' --no-i-r --human-readable --info=progress2 kernel/clean/* kernel/build

# Copy our good config into output
cp kernel/good.config kernel/out/.config
#make O=./kernel/out -C ./kernel/clean menuconfig -j8
make \
    O=../out \
    -C ./kernel/clean \
    ARCH=arm64 \
    CROSS_COMPILE=../aarch64-linux-android-4.9/bin/aarch64-linux-android- \
    -j8

# Set up mkbootimg
make -C kernel/mkbootimg

# Download ramdisk
if [[ ! -f kernel/ramdisk.cpio.gz ]]; then
    wget \
        -nc \
        -O kernel/ramdisk.cpio.gz \
        https://gemian.thinkglobally.org/ramdisk.cpio.gz
fi

if [[ ! -f kernel/out/arch/arm64/boot/Image.gz-dtb ]]; then
    echo "Failed to build kernel!"
    exit 255
fi

if [[ -f kernel/linux_boot.img ]]; then
    rm kernel/linux_boot.img;
fi

# Make bootimage
./kernel/mkbootimg/mkbootimg \
    --kernel kernel/out/arch/arm64/boot/Image.gz-dtb \
    --ramdisk kernel/ramdisk.cpio.gz \
    --base 0x40080000 \
    --second_offset 0x00e80000 \
    --cmdline "bootopt=64S3,32N2,64N2 log_buf_len=4M" \
    --kernel_offset 0x00000000 \
    --ramdisk_offset 0x04f80000 \
    --tags_offset 0x03f80000 \
    --pagesize 2048 \
    -o kernel/linux_boot.img