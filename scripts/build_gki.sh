#!/bin/bash
# build_gki.sh: configure and build the bare ACK 6.18 arm64 GKI Image.
set -e
. "$(dirname "$0")/env.sh"
mkdir -p "$ROOT/out" "$O"
bash "$ROOT/tools/config_gki.sh" "$C" "$O"
"${M[@]}" -j"$(nproc)" Image > "$ROOT/out/build.log" 2>&1
echo "build_gki: $(cat "$O/include/config/kernel.release")"
ls -l "$O/arch/arm64/boot/Image"
