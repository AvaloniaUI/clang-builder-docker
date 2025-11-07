#!/bin/bash
set -e
set -x

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/common.sh"

run_script() {
  TARGET=$1 # aarch64-linux-gnu
  
  BUILDDIR=/sysroots/$TARGET/test-build
  mkdir -p $BUILDDIR
  cd $BUILDDIR
  
  cmake \
    -S /scripts/test \
    -DCMAKE_TOOLCHAIN_FILE=/toolchains/$TARGET.toolchain \
  
  make
  chroot /sysroots/$TARGET /test-build/test
  rm -rf /test-build
}
  
run_targets "$1" 
