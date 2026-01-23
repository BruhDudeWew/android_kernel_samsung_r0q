#!/bin/bash

# This is just a really simple build script that set some variables and build flags
# that too long for me to bother remembering

export VARIANTS=gki
export MSM_ARCH=waipio
export ANDROID_MAJOR_VERSION=s
export PLATFORM_VERSION=12
export CCACHE_DIR="$(pwd)/.ccache"
make O="$(pwd)/out" ARCH=arm64 LLVM=1 LLVM_IAS=1 CC='ccache clang' CROSS_COMPILE=aarch64-linux-gnu- bruh-waipio-gki_defconfig
make O="$(pwd)/out" ARCH=arm64 LLVM=1 LLVM_IAS=1 CC='ccache clang' CROSS_COMPILE=aarch64-linux-gnu- menuconfig
make O="$(pwd)/out" ARCH=arm64 LLVM=1 LLVM_IAS=1 CC='ccache clang' CROSS_COMPILE=aarch64-linux-gnu- -j$(nproc) Image
