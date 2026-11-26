#!/bin/bash
# fetch-612.sh: ACK android16-6.12 + mkbootimg, shallow and pinned.
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

fetch src/common https://android.googlesource.com/kernel/common 105b5745f1d771060aa9fb7f75821f69bb2298fd
fetch src/mkbootimg https://android.googlesource.com/platform/system/tools/mkbootimg f5c284e8998dd8a085cf027bb518b6c2b84cf744