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
    -j10
    ARCH=arm64
    LLVM=1
    LLVM_IAS=1
    CROSS_COMPILE=aarch64-linux-gnu-
    O="$KERNEL_OUT_DIR"
)
TOOLCHAINS_PATH="$HOME/Toolchains/clang-r416183b"

# Important Android export
export VARIANTS=gki
export MSM_ARCH=waipio
export ANDROID_MAJOR_VERSION=s
export PLATFORM_VERSION=12

echo "Check the script for some settings that may needed to be change"
echo "For example, how many threads will 'make' use. Too much can cause out of memory error"
read -p "Press enter to continue"

CLANG_VERSION=$($TOOLCHAINS_PATH/bin/clang --version)

if [[ "$CLANG_VERSION" != *Android* || "$CLANG_VERSION" != *r416183b* ]]; then
  echo "Warning: Expected Android clang r416183b, got: "
  echo "$CLANG_VERSION"
  read -r -p "If this is intended (You wanted to try newer NDK), press y. Anything else cancel the script: " answer
  [[ "$answer" =~ ^[Yy]$ ]] || exit 1
fi

export PATH=$TOOLCHAINS_PATH/bin:$PATH
export ELFEDIT=aarch64-linux-gnu-elfedit

if ! command -v "$ELFEDIT" >/dev/null 2>&1; then
    echo "Error: Missing $ELFEDIT in PATH"
    echo "Without it, the build will still succeed but the kernel won't be bootable"
    read -r -p "Create one in toolchain's bin folder? [Y/n] " answer
    [[ "$answer" =~ ^[Yy]$ ]] || exit 1
    touch $TOOLCHAINS_PATH/bin/$ELFEDIT
    chmod +x $TOOLCHAINS_PATH/bin/$ELFEDIT
fi

if [ $RESUKISU -eq 1 ]; then
    echo -e "\nReSukiSU enabled"
    if [ $SUSFS -eq 1 ]; then
        echo -e "\nImplementing and fixing SuSFS"
        echo "Note: This will only patch SuSFS on kernel-side and will not handle KernelSU patching"
        FIX_FILES=("$KERNEL_ROOT"/fix/*.patch)
        SUSFS_DIR="$KERNEL_ROOT/susfs4ksu"
        cp -r $SUSFS_DIR/kernel_patches/fs $KERNEL_ROOT
        cp -r $SUSFS_DIR/kernel_patches/include $KERNEL_ROOT
        patch -p1 -N --no-backup-if-mismatch < $SUSFS_DIR/kernel_patches/50_add_susfs_in_gki-android12-5.10.patch
        for p in "${FIX_FILES[@]}"; do patch -p0 -N --no-backup-if-mismatch < "$p"; done
    fi
elif [ $SUSFS -eq 1 ]; then
    echo "SuSFS enabled. But ReSukiSU isn't."
    echo "Please enable ReSukiSU or disable SuSFS"
    exit 1
fi

make "${MAKEOPTS[@]}" waipio-gki_defconfig bruh-common.config droidspaces.config

if [ $RESUKISU -ne 1 ]; then
    $CONFIG_SCRIPT --file "$CONFIG_FILE" --disable KSU
elif [ $RESUKISU -eq 1 ]; then
    $CONFIG_SCRIPT --file "$CONFIG_FILE" --enable KSU
    if [ $SUSFS -eq 1 ]; then $CONFIG_SCRIPT --file "$CONFIG_FILE" --enable KSU_SUSFS; fi
fi

if [ $MENUCONFIG -eq 1 ]; then make "${MAKEOPTS[@]}" menuconfig; fi

make "${MAKEOPTS[@]}" Image
