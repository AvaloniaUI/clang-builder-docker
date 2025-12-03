# CLang portable cross-toolchain

This repository contains the source and build recipes for a universal Docker image that provides:
- Clang 21 toolchain
- libc++ (C++ standard library), libunwind and compiler-rt from LLVM 21 built from source
- Compiler-rt / libunwind as needed 
- Sysroots for cross-compilation:
  - aarch64 glibc (Debian 11)
  - amd64 glibc (Debian 11)
  - TBD

## Quick usage
- Pull the prebuilt Docker image:
  docker pull ghcr.io/avaloniaui/clang-cross-builder:latest

- Run an interactive container:
  docker run --rm -it -v "$(pwd)":/work ghcr.io/avaloniaui/clang-cross-builder:latest /bin/bash

- Inside the container, use the provided cmake toolchain file:
    ```
    cmake -S /path/to/source \
      -DCMAKE_TOOLCHAIN_FILE=/toolchains/aarch64-linux-gnu.toolchain \
      ...
    ```

## Extracting sysroots and toolchains

If you need to use your system toolchain for some reason (e. g. CLion insists on using debugger from the same docker container that was used to build the project), you can extract the sysroots and toolchain files from the image:

`docker run --rm -v "$(pwd)"/toolchains:/host ghcr.io/avaloniaui/clang-cross-builder:latest /scripts/extract-toolchain.sh`

Make sure that clang version matches the one in the image.

## Purpose
- Produce a self-contained, reproducible Docker image suitable for building and distributing C++21 binaries that use libc++21 and can run on older glibc-based Linux distributions.
- Avoid dependence on GCC/libgcc toolchain components — the image is built around LLVM/Clang toolchain primitives (clang, lld, compiler-rt, libc++/libc++abi, libunwind).

### Why this approach
- Many modern C++ projects rely on libc++ features and Clang-specific toolchains. Distributing binaries that run on older distros requires building against older glibc or producing compatible artifacts.
- By providing a controlled image with clang 21 + libc++ 21 and careful sysrooting against Debian 11, you can produce binaries that run on Debian 11 and similar ancient glibc targets without requiring end-user compilers.
- The build avoids GCC and libgcc entirely; runtime dependencies are resolved with libc++/libunwind/clang-built runtime libs.

## Notes and constraints
- GCC, libgcc and GCC-provided runtimes are intentionally not used anywhere. Runtimes come from compiler-rt, libc++/libc++abi and libunwind built with Clang and are statically linked
- The current canonical runtime target is Debian 11 (glibc compatible). The image is intended to produce artifacts compatible with that distro or newer.
