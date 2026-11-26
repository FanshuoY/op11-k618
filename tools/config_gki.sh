#!/bin/bash
# config_gki.sh <kernel src> <out dir>: gki_defconfig plus the minimum this port needs.
set -e
C=$(cd "$1" && pwd); O=$2
M=(make -C "$C" O="$O" ARCH=arm64 LLVM=1 LLVM_IAS=1)
mkdir -p "$O"
"${M[@]}" gki_defconfig > "$O/../gki-config.log" 2>&1
# STATIC_USERMODEHELPER off: the future batch loader is a usermode helper.
# MEMCG_V1: ColorOS mounts the v1 memory cgroup (the stock 5.15 kernel offers it).
# Module signatures: SHA-256 (the stock GKI modules use SHA-256).
# LOCALVERSION is the release tag every future module must match.
# BTF: Android's BPF tools read /sys/kernel/btf/vmlinux (gki_defconfig has it; keep it explicit).
"$C/scripts/config" --file "$O/.config" \
	-d STATIC_USERMODEHELPER \
	-e MEMCG_V1 \
	-e DEBUG_INFO_BTF \
	-e MODULE_ALLOW_BTF_MISMATCH \
	-e MODULE_SIG_SHA256 -d MODULE_SIG_SHA1 \
	--set-str LOCALVERSION "-xigua.k618" -d LOCALVERSION_AUTO
"${M[@]}" olddefconfig >> "$O/../gki-config.log" 2>&1
for c in MEMCG_V1 DEBUG_INFO_BTF MODULE_SIG_SHA256; do
	grep -q "^CONFIG_$c=y" "$O/.config" || { echo "config_gki: CONFIG_$c did not take"; exit 1; }
done
grep -q '^# CONFIG_STATIC_USERMODEHELPER is not set' "$O/.config" || { echo "config_gki: STATIC_USERMODEHELPER still on"; exit 1; }
echo "config_gki: ok ($(grep '^CONFIG_MODULE_SIG_HASH' "$O/.config"))"
