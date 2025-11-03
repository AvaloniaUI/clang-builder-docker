# ===== Update slim debian images with -dev packages

# ARM64
FROM --platform=linux/arm64 debian:buster-20240612-slim AS baseroot-arm64
COPY scripts/stretch.sources.list /etc/apt/sources.list
RUN apt-get update && apt-get install -y --no-install-recommends libfontconfig-dev libc6-dev symlinks  && rm -rf /var/cache/apt/archives /var/lib/apt/lists/*
RUN symlinks -cr /

# Add random libraries used by CMake to detect compiler features
#FROM baseroot-arm64 AS buildroot-arm64
#RUN apt-get update && apt-get install -y --no-install-recommends libstdc++6-dev libgcc-8-dev  && rm -rf /var/cache/apt/archives /var/lib/apt/lists/*
#RUN symlinks -cr /

# AMD64
FROM --platform=linux/amd64 debian:buster-20240612-slim AS baseroot-amd64
COPY scripts/stretch.sources.list /etc/apt/sources.list
RUN apt-get update && apt-get install -y --no-install-recommends libfontconfig-dev libc6-dev symlinks && rm -rf /var/cache/apt/archives /var/lib/apt/lists/*
RUN symlinks -cr /

# ====== Fix symlinks in sysroots and build static libc++ and friends =======
FROM silkeh/clang:20-bookworm AS build
RUN apt-get update && apt-get install -y symlinks ninja-build zlib1g-dev libzstd-dev libxml2-dev libcurl4-openssl-dev libclang-20-dev && rm -rf /var/cache/apt/archives /var/lib/apt/lists/* 

COPY --from=baseroot-amd64 . /sysroots/amd64-linux-gnu
#COPY --from=buildroot-arm64 . /sysroots/aarch64-linux-gnu
COPY --from=baseroot-arm64 . /sysroots/aarch64-linux-gnu

COPY llvm-project /src/llvm

RUN rm /usr/bin/ld && ln -s /usr/bin/ld.lld /usr/bin/ld

COPY scripts/build-sysroot.sh /scripts/build-sysroot.sh

RUN /scripts/build-sysroot.sh aarch64-linux-gnu
RUN /scripts/build-sysroot.sh amd64-linux-gnu

# ======= Final image =======

FROM silkeh/clang:20-bookworm

# glibc amd64
COPY --from=baseroot-amd64 . /sysroots/amd64-linux-gnu
COPY --from=build /out/amd64-linux-gnu /sysroots/amd64-linux-gnu

# glibc aarch64
COPY --from=baseroot-arm64 . /sysroots/aarch64-linux-gnu
COPY --from=build /out/aarch64-linux-gnu /sysroots/aarch64-linux-gnu

# Replace linker because gnu binutils is cancer
RUN rm /usr/bin/ld && ln -s /usr/bin/ld.lld /usr/bin/ld

# Make builtins visible to clang
RUN mkdir -p /usr/lib/llvm-20/lib/clang/20/lib/aarch64-unknown-linux-gnu/
RUN ln -s /sysroots/aarch64-linux-gnu/usr/lib/linux/libclang_rt.builtins-aarch64.a \
    /usr/lib/llvm-20/lib/clang/20/lib/aarch64-unknown-linux-gnu/libclang_rt.builtins.a
RUN ln -s /sysroots/aarch64-linux-gnu/usr/lib/linux/clang_rt.crtbegin-aarch64.o \
    /usr/lib/llvm-20/lib/clang/20/lib/aarch64-unknown-linux-gnu/clang_rt.crtbegin.o
RUN ln -s /sysroots/aarch64-linux-gnu/usr/lib/linux/clang_rt.crtend-aarch64.o \
    /usr/lib/llvm-20/lib/clang/20/lib/aarch64-unknown-linux-gnu/clang_rt.crtend.o
COPY toolchains /toolchains
