#!/bin/bash
set -x
set -e
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/common.sh"

run_script() {
  TARGET_TRIPLE=$1

  SYSROOT_PATH="/sysroots/${TARGET_TRIPLE}"
  BUILDDIR=/build/$TARGET_TRIPLE
  INSTALL_PATH=$SYSROOT_PATH
  COMPILE_FLAGS="--target=${TARGET_TRIPLE} -fPIC"

  mkdir -p "$BUILDDIR"
  cd "$BUILDDIR"
  #
  #
  cmake \
      -G "Ninja" \
      -DCMAKE_BUILD_TYPE=Release \
      -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi;libunwind;compiler-rt" \
      -DCMAKE_INSTALL_PREFIX=/usr \
      -DCMAKE_C_COMPILER=clang \
      -DCMAKE_CXX_COMPILER=clang++ \
      -DCMAKE_SYSROOT="$SYSROOT_PATH" \
      -DCMAKE_ASM_COMPILER_TARGET="$TARGET_TRIPLE" \
      -DCMAKE_ASM_FLAGS="${COMPILE_FLAGS}" \
      -DCMAKE_C_COMPILER_TARGET="$TARGET_TRIPLE" \
      -DCMAKE_C_FLAGS="${COMPILE_FLAGS}" \
      -DCMAKE_CXX_COMPILER_TARGET="$TARGET_TRIPLE" \
      -DCMAKE_CXX_FLAGS="${COMPILE_FLAGS}" \
      -DLLVM_DEFAULT_TARGET_TRIPLE="$TARGET_TRIPLE" \
      -DLLVM_HOST_TRIPLE="$TARGET_TRIPLE" `# needed for compiler-rt, because cross-build is broken` \
      -DLIBCXX_USE_COMPILER_RT=ON \
      -DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=ON \
      -DLIBCXX_ENABLE_SHARED=OFF \
      -DLIBCXXABI_ENABLE_SHARED=OFF \
      -DLIBCXXABI_USE_LLVM_UNWINDER=YES \
      -DLIBUNWIND_ENABLE_SHARED=OFF \
      -DCMAKE_C_COMPILER_WORKS=1 \
      -DCMAKE_CXX_COMPILER_WORKS=1 \
      -DLLVM_ENABLE_LIBCXX=ON \
      -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY \
      `#compiler-rt stuff` \
      -DCOMPILER_RT_BUILD_BUILTINS=ON \
      -DCOMPILER_RT_BUILD_LIBFUZZER=OFF \
      -DCOMPILER_RT_BUILD_MEMPROF=OFF \
      -DCOMPILER_RT_BUILD_PROFILE=OFF \
      -DCOMPILER_RT_BUILD_CTX_PROFILE=OFF \
      -DCOMPILER_RT_BUILD_SANITIZERS=OFF \
      -DCOMPILER_RT_BUILD_XRAY=OFF \
      -DCOMPILER_RT_BUILD_ORC=OFF \
      -DCOMPILER_RT_BUILD_CRT=ON \
      /src/llvm/runtimes


   #ninja compiler-rt
  #ninja install-cxx install-cxxabi install-unwind compiler-rt
  ninja cxx unwind cxxabi compiler-rt
  DESTDIR="$INSTALL_PATH" ninja install-cxx install-unwind install-cxxabi install-compiler-rt

  # Create a fake libgcc_s.a to satisfy the linker
  ar -r "$INSTALL_PATH/usr/lib/libgcc_s.a"
  ln -s $INSTALL_PATH/usr/lib/linux/clang_rt.crtbegin*.o $INSTALL_PATH/usr/lib/crtbeginS.o
  ln -s $INSTALL_PATH/usr/lib/linux/clang_rt.crtend*.o $INSTALL_PATH/usr/lib/crtendS.o
  symlinks -cr $INSTALL_PATH
  
  # Verify that sysroot works
  /scripts/install_clang_builtins.sh $TARGET_TRIPLE
  /scripts/check-compile.sh $TARGET_TRIPLE

}


# Invoke run_targets with the provided argument
run_targets "$1"
