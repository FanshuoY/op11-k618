#!/bin/bash
# build_bootimg.sh: pack Image + PJA110 FDT as a header-v4 boot image with an AVB footer.
# No vendor modules and no initramfs: this is the M0.2 diagnostic image only.
set -e
. "$(dirname "$0")/env.sh"
DEVICE=${DEVICE:-xigua}
CMDLINE=${CMDLINE:-$(cat "$ROOT/device/$DEVICE/cmdline.txt")}
FDT=$ROOT/device/$DEVICE/fdt.dtb
[ -s "$FDT" ] || { echo "build_bootimg: missing $FDT" >&2; exit 1; }
mkdir -p "$ROOT/out"

cat "$O/arch/arm64/boot/Image" "$FDT" > "$ROOT/out/Image-dtb"
python3 "$ROOT/src/mkbootimg/mkbootimg.py" \
	--header_version 4 \
	--kernel "$ROOT/out/Image-dtb" \
	--cmdline "$CMDLINE" \
	--os_version 13.0.0 --os_patch_level 2025-11 \
	-o "$ROOT/out/boot.img"

python3 "$ROOT/src/avb/avbtool.py" add_hash_footer \
	--image "$ROOT/out/boot.img" \
	--partition_name boot \
	--partition_size 201326592 \
	--algorithm NONE \
	--salt d716067806deff6786d8c63c2f6f9c4d \
	--prop com.android.build.boot.os_version:13 \
	--prop 'com.android.build.boot.fingerprint:OnePlus/PJA110/OP5943L1:15/AP3A.240617.008/T.1baf1ee_502b7e_502b7f:user/release-keys' \
	--prop com.android.build.boot.security_patch:2025-11-01

python3 "$ROOT/src/avb/avbtool.py" verify_image --image "$ROOT/out/boot.img" > "$ROOT/out/avb.txt"
cp "$ROOT/out/boot.img" "$ROOT/out/diag-nolayer.img"
echo "build_bootimg: $(cat "$O/include/config/kernel.release")"
ls -l "$ROOT/out/Image-dtb" "$ROOT/out/diag-nolayer.img"
