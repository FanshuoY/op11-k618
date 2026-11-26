#!/bin/bash
# build-612.sh: ACK 6.12 arm64 GKI Image + a no-DTB/no-AVB diagnostic boot image.
set -e
ROOT=$(cd "$(dirname "$0")/.." && pwd)
C=$ROOT/src/common
O=$ROOT/out/gki
export PATH=/usr/lib/llvm-18/bin:$PATH
export KBUILD_BUILD_HOST=github-actions KBUILD_BUILD_USER=fanshuo KBUILD_BUILD_VERSION=1
export KBUILD_BUILD_TIMESTAMP="Thu Nov 26 00:00:00 UTC 2026"
M=(make -C "$C" O="$O" ARCH=arm64 LLVM=1 LLVM_IAS=1 KCPPFLAGS=-D__ANDROID_COMMON_KERNEL__)

mkdir -p "$ROOT/out" "$O"
"${M[@]}" gki_defconfig > "$ROOT/out/gki-config.log" 2>&1
"$C/scripts/config" --file "$O/.config" \
	-d RUST \
	-d DEBUG_INFO -d DEBUG_INFO_BTF -d DEBUG_INFO_DWARF5 \
	-d LTO_CLANG_THIN -d LTO_CLANG_FULL -e LTO_NONE \
	-d CFI_CLANG \
	-d ARM64_SME -d ARM64_PSEUDO_NMI \
	--set-str LOCALVERSION "-xigua.k612" -d LOCALVERSION_AUTO
"${M[@]}" olddefconfig >> "$ROOT/out/gki-config.log" 2>&1
"${M[@]}" -j"$(nproc)" Image > "$ROOT/out/build.log" 2>&1

CMDLINE=$(cat "$ROOT/device/xigua/cmdline-612.txt")
python3 "$ROOT/src/mkbootimg/mkbootimg.py" \
	--header_version 4 \
	--kernel "$O/arch/arm64/boot/Image" \
	--cmdline "$CMDLINE" \
	--os_version 13.0.0 --os_patch_level 2025-11 \
	-o "$ROOT/out/boot-612.img"

echo "build-612: $(cat "$O/include/config/kernel.release")"
ls -l "$O/arch/arm64/boot/Image" "$ROOT/out/boot-612.img"