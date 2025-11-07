# ===== Update slim debian images with -dev packages

# ARM64
FROM --platform=linux/arm64 debian:buster-20240612-slim AS baseroot-arm64
COPY scripts/stretch.sources.list /etc/apt/sources.list
RUN apt-get update && apt-get install -y --no-install-recommends libfontconfig-dev libc6-dev symlinks pax-utils && rm -rf /var/cache/apt/archives /var/lib/apt/lists/*
RUN symlinks -cr /

# ARMHF
FROM --platform=linux/arm/v7 debian:buster-20240612-slim AS baseroot-armhf
COPY scripts/stretch.sources.list /etc/apt/sources.list
RUN apt-get update && apt-get install -y --no-install-recommends libfontconfig-dev libc6-dev symlinks pax-utils && rm -rf /var/cache/apt/archives /var/lib/apt/lists/*
RUN symlinks -cr /

# AMD64
FROM --platform=linux/amd64 debian:buster-20240612-slim AS baseroot-x86_64
COPY scripts/stretch.sources.list /etc/apt/sources.list
RUN apt-get update && apt-get install -y --no-install-recommends libfontconfig-dev libc6-dev symlinks pax-utils && rm -rf /var/cache/apt/archives /var/lib/apt/lists/*
RUN symlinks -cr /

# Container with LLVM toolchain
FROM  debian:bookworm-20251103 AS llvm-base
RUN apt-get update && apt-get install --no-install-recommends -y wget symlinks ninja-build cmake git ninja-build pax-utils strace make  gnupg software-properties-common && rm -rf /var/cache/apt/archives /var/lib/apt/lists/* 
RUN wget --no-check-certificate https://apt.llvm.org/llvm.sh -O /tmp/llvm.sh && chmod +x /tmp/llvm.sh && /tmp/llvm.sh 21 all && rm /tmp/llvm.sh && rm -rf /var/cache/apt/archives /var/lib/apt/lists/* 

RUN bash -c 'set -x; ls /usr/bin/*|grep 21$|while read bin; do ln -s $bin ${bin%-21}; done;'

# Container with extra stuff required for building libc++/unwind/compiler-rt
FROM llvm-base AS build-base

RUN apt-get update && apt-get install -y zlib1g-dev libzstd-dev libxml2-dev libcurl4-openssl-dev && rm -rf /var/cache/apt/archives /var/lib/apt/lists/* 
COPY llvm-project /src/llvm

RUN rm -f /usr/bin/ld && ln -s /usr/bin/ld.lld /usr/bin/ld

COPY scripts /scripts
COPY toolchains /toolchains

FROM build-base AS build-aarch64
COPY --from=baseroot-arm64 . /sysroots/aarch64-linux-gnu
RUN /scripts/build-sysroot.sh aarch64-linux-gnu

FROM build-base AS build-armhf
COPY --from=baseroot-armhf . /sysroots/arm-linux-gnueabihf
RUN /scripts/build-sysroot.sh arm-linux-gnueabihf

FROM build-base AS build-x86_64
COPY --from=baseroot-x86_64 . /sysroots/x86_64-linux-gnu
RUN /scripts/build-sysroot.sh x86_64-linux-gnu

# ======= Final image =======

FROM llvm-base

# glibc x86_64
COPY --from=build-x86_64 /sysroots/x86_64-linux-gnu /sysroots/x86_64-linux-gnu

# glibc aarch64
COPY --from=build-aarch64 /sysroots/aarch64-linux-gnu /sysroots/aarch64-linux-gnu

# glibc armhf
COPY --from=build-armhf /sysroots/arm-linux-gnueabihf /sysroots/arm-linux-gnueabihf

COPY scripts /scripts
COPY toolchains /toolchains


# Replace linker because gnu binutils is cancer
RUN rm /usr/bin/ld && ln -s /usr/bin/ld.lld /usr/bin/ld

RUN /scripts/install_clang_builtins.sh && /scripts/check-compile.sh && rm -rf /scripts
COPY scripts/dist /scripts
