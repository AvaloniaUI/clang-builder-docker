#!/bin/bash
set -x
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/common.sh"

run_script() {

  TARGET_TRIPLE=$1
  CLANG_DIR_NAME=`echo $TARGET_TRIPLE | sed 's/-linux-gnu/-unknown-linux-gnu/g'`
  
  CLANG_LIBRARY_DIR=/usr/lib/llvm-21/lib/clang/21/lib/$CLANG_DIR_NAME
  SRC_DIR=/sysroots/$TARGET_TRIPLE/usr/lib/linux
  
  mkdir -p $CLANG_LIBRARY_DIR
  ln -s $SRC_DIR/libclang_rt.builtins-*.a $CLANG_LIBRARY_DIR/libclang_rt.builtins.a
  #ln -s $SRC_DIR/clang_rt.crtbegin-*.o $CLANG_LIBRARY_DIR/clang_rt.crtbegin.o
  #ln -s $SRC_DIR/clang_rt.crtend-*.o $CLANG_LIBRARY_DIR/clang_rt.crtend.o
}

run_targets "$1" 
