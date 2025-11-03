#!/bin/bash
set -e
set -x
#-Wl,-L,/sysroots/aarch64-linux-gnu/usr/lib
BUILDDIR=/sysroots/aarch64-linux-gnu/test-build
mkdir -p $BUILDDIR
cd $BUILDDIR

cmake \
  -S /test \
  -DCMAKE_TOOLCHAIN_FILE=/toolchains/aarch64-linux-gnu.toolchain \

make
file ./test
chroot /sysroots/aarch64-linux-gnu /test-build/test