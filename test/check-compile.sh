#!/bin/bash
set -e
set -x
#-Wl,-L,/sysroots/aarch64-linux-gnu/usr/lib
BUILDDIR=/sysroots/aarch64-linux-gnu/test-build
mkdir -p $BUILDDIR
cd $BUILDDIR
COMPILE_FLAGS="--target=aarch64-linux-gnu --sysroot=/sysroots/aarch64-linux-gnu -rtlib=compiler-rt -stdlib=libc++"
LINKER_FLAGS="--target=aarch64-linux-gnu --sysroot=/sysroots/aarch64-linux-gnu -stdlib=libc++ -rtlib=compiler-rt -fuse-ld=lld -lc++ -lc++abi -lunwind -lm -lc" 

cmake \
  -S /test \
  -DCMAKE_SYSROOT=/sysroots/aarch64-linux-gnu \
  -DCMAKE_C_COMPILER=/usr/bin/clang \
  -DCMAKE_CXX_COMPILER=/usr/bin/clang++ \
  -DCMAKE_C_COMPILER_TARGET=aarch64-linux-gnu \
  -DCMAKE_CXX_COMPILER_TARGET=aarch64-linux-gnu \
  -DCMAKE_C_FLAGS="${COMPILE_FLAGS}" \
  -DCMAKE_CXX_FLAGS="${COMPILE_FLAGS} -stdlib=libc++" \
  -DCMAKE_EXE_LINKER_FLAGS="${LINKER_FLAGS}" \
  -DCMAKE_SHARED_LINKER_FLAGS="${LINKER_FLAGS}" \

make
file ./test
chroot /sysroots/aarch64-linux-gnu /test-build/test