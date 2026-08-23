#!/bin/bash

# Simple kernel building script
# Made by BruhDudeWew
# Inspired by ravindu644's build script


set -uo pipefail

# Settings
MENUCONFIG=1
RESUKISU=1
SUSFS=1
KERNEL_ROOT=$(pwd)
KERNEL_OUT_DIR="$KERNEL_ROOT/out"
CONFIG_SCRIPT="$KERNEL_ROOT/scripts/config"
CONFIG_FILE="$KERNEL_ROOT/out/.config"
MAKEOPTS=(
    -j"$(nproc --all)"
    ARCH=arm64
    LLVM=1
    LLVM_IAS=1
    CROSS_COMPILE=aarch64-linux-gnu-
    O="$KERNEL_OUT_DIR"
)

# Important Android export
export VARIANTS=gki
export MSM_ARCH=waipio
export ANDROID_MAJOR_VERSION=s
export PLATFORM_VERSION=12



susfs_implement(){
    echo -e "\nImplementing and fixing SuSFS"
    echo "Note: This will only patch SuSFS on kernel-side and will not handle KernelSU patching"
    FIX_FILES=("$KERNEL_ROOT"/fix/*.patch)
    SUSFS_DIR="$KERNEL_ROOT/susfs4ksu"
    cp -r $SUSFS_DIR/kernel_patches/fs $KERNEL_ROOT
    cp -r $SUSFS_DIR/kernel_patches/include $KERNEL_ROOT
    patch -p1 --no-backup-if-mismatch < $SUSFS_DIR/kernel_patches/50_add_susfs_in_gki-android12-5.10.patch
    patch -p0 --no-backup-if-mismatch < $FIX_FILES
}

echo "Attention: The scipt is really simple and assume a lot of things, including: "
echo "  - You have clang-r416183b in PATH"
echo "  - You have installed basic tools needed for building a Linux Kernel"
echo "  - You have an empty aarch64-linux-gnu-elfedit with executable permission set (Yeah you needed it or else the kernel gonna skip some stuffs and make it unbootable)"
echo "  - The script is running in the kernel's dir"
echo -e "\nThe point of this script is to just automate SuSFS patching for me. That's all"
echo "If you're sure: "
read -p "Press enter to continue"

if [ $RESUKISU -eq 1 ]; then
    echo -e "\nReSukiSU enabled"

    if [ $SUSFS -eq 1 ]; then
        echo "SuSFS enabled"
        susfs_implement
    fi

elif [ $SUSFS -eq 1 ]; then
    echo "SuSFS enabled. But ReSukiSU isn't."
    echo "Please enable ReSukiSU or disable SuSFS"
    exit 1
fi

make "${MAKEOPTS[@]}" waipio-gki_defconfig bruh-common.config droidspaces.config
if [ $RESUKISU -ne 1 ]; then
    $CONFIG_SCRIPT --file "$CONFIG_FILE" -d CONFIG_KSU
    $CONFIG_SCRIPT --file "$CONFIG_FILE" -e CONFIG_KSU_SUSFS
fi

make "${MAKEOPTS[@]}" Image
