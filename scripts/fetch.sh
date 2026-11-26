#!/bin/bash
# fetch.sh: the M0 inputs at pinned revisions (shallow). Idempotent.
set -e
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"

fetch() {
	local path=$1 url=$2 rev=$3
	if [ -d "$path/.git" ] && git -C "$path" rev-parse -q --verify HEAD > /dev/null; then
		echo "$path: present ($(git -C "$path" rev-parse --short HEAD))"
		return
	fi
	mkdir -p "$path"
	git -C "$path" init -q
	git -C "$path" remote add origin "$url" 2> /dev/null || true
	git -C "$path" fetch -q --depth 1 --no-tags origin "$rev"
	git -C "$path" -c advice.detachedHead=false checkout -q FETCH_HEAD
	echo "$path: $(git -C "$path" rev-parse --short HEAD)"
}

# ACK android17-6.18, 6.18.32 (same baseline as the op13 and SM8550 reference ports)
fetch src/common https://android.googlesource.com/kernel/common ff4a6c3bb0f471a9dd186293a47b62c83829b97d
# boot image tool (header v4)
fetch src/mkbootimg https://android.googlesource.com/platform/system/tools/mkbootimg f5c284e8998dd8a085cf027bb518b6c2b84cf744
