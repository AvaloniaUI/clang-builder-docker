# CLang portable cross-toolchain

This repository contains the source and build recipes for a universal Docker image that provides:
- Clang 20 toolchain (based on https://github.com/silkeh/docker-clang image)
- libc++ (C++ standard library), libunwind and compiler-rt from LLVM 20 built from source
- Compiler-rt / libunwind as needed 
- Sysroots for cross-compilation:
  - aarch64 glibc (Debian 11)
  - amd64 glibc (Debian 11)
  - TBD

## Purpose
- Produce a self-contained, reproducible Docker image suitable for building and distributing C++20 binaries that use libc++20 and can run on older glibc-based Linux distributions.
- Avoid dependence on GCC/libgcc toolchain components — the image is built around LLVM/Clang toolchain primitives (clang, lld, compiler-rt, libc++/libc++abi, libunwind).

### Why this approach
- Many modern C++ projects rely on libc++ features and Clang-specific toolchains. Distributing binaries that run on older distros requires building against older glibc or producing compatible artifacts.
- By providing a controlled image with Clang20 + libc++20 and careful sysrooting against Debian 11, you can produce binaries that run on Debian 11 and similar ancient glibc targets without requiring end-user compilers.
- The build avoids GCC and libgcc entirely; runtime dependencies are resolved with libc++/libunwind/clang-built runtime libs.

## Quick usage
- Build the Docker image (from repository root):
  docker build -t clang-builder .

- Run an interactive container:
  docker run --rm -it -v "$(pwd)":/work clang-builder /bin/bash

- Inside the container, example cross-compile workflow:
  - Set up a sysroot or use the provided Debian 11 rootfs (if present).
  - Use clang/clang++:
    ```
      export CC=clang
      export CXX=clang++
      clang++ --target=x86_64-linux-gnu --sysroot=/path/to/debian11-sysroot \
              -stdlib=libc++ -Wl,--whole-archive -lc++ -Wl,--no-whole-archive \
              -o myprog src/main.cpp
    ```
  - Or use provided cmake toolchain file:
    ```
    cmake -S /path/to/source \
      -DCMAKE_TOOLCHAIN_FILE=/toolchains/aarch64-linux-gnu.toolchain \
    ```

## Extracting sysroots and toolchains

If you need to use your system toolchain for some reason (e. g. CLion insists on using debugger from the same docker container that was used to build the project), you can extract the sysroots and toolchain files from the image:

`docker run --rm -v "$(pwd)"/toolchains:/host clang-builder /scripts/extract-toolchain.sh`

## Notes and constraints
- GCC, libgcc and GCC-provided runtimes are intentionally not used anywhere. Runtimes come from compiler-rt, libc++/libc++abi and libunwind built with Clang and are statically linked
- The current canonical runtime target is Debian 11 (glibc compatible). The image is intended to produce artifacts compatible with that distro or newer.
