#!/bin/bash
# build_bootimg.sh: pack the bare Image as a header-v4 boot image for `fastboot boot`.
# No ramdisk, no vendor modules: this is the M0 diagnostic image only.
set -e
. "$(dirname "$0")/env.sh"
CMDLINE=${CMDLINE:-$(cat "$ROOT/device/salami/cmdline.txt")}
mkdir -p "$ROOT/out"
python3 "$ROOT/src/mkbootimg/mkbootimg.py" \
	--header_version 4 \
	--kernel "$O/arch/arm64/boot/Image" \
	--cmdline "$CMDLINE" \
	-o "$ROOT/out/diag-nolayer.img"
echo "build_bootimg: $(cat "$O/include/config/kernel.release")"
ls -l "$ROOT/out/diag-nolayer.img"
