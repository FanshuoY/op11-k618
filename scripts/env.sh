#!/bin/bash
# env.sh: paths and toolchain for the M0 build (sourced).
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
C=$ROOT/src/common
O=$ROOT/out/gki

# LLVM 22 (what ACK android17-6.18 is built with; the CI installs clang-22)
for d in /usr/lib/llvm-22/bin; do
	[ -x "$d/clang" ] && { PATH=$d:$PATH; break; }
done
if [ "${USE_CCACHE:-1}" = 1 ] && command -v ccache > /dev/null; then
	mkdir -p "$ROOT/toolchain/ccache-bin"
	ln -sfn "$(command -v ccache)" "$ROOT/toolchain/ccache-bin/clang"
	PATH=$ROOT/toolchain/ccache-bin:$PATH
	export CCACHE_BASEDIR=$ROOT CCACHE_NOHASHDIR=1 CCACHE_SLOPPINESS=time_macros,include_file_mtime,include_file_ctime
fi
export PATH
export KBUILD_BUILD_HOST=github-actions KBUILD_BUILD_USER=fanshuo KBUILD_BUILD_VERSION=1
export KBUILD_BUILD_TIMESTAMP="Thu Nov 26 00:00:00 UTC 2026"
M=(make -C "$C" O="$O" ARCH=arm64 LLVM=1 LLVM_IAS=1 KCPPFLAGS=-D__ANDROID_COMMON_KERNEL__)
