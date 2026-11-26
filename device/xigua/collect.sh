#!/system/bin/sh
# collect.sh - run on the PJA110 / xigua as root, save a snapshot for the port.
# Usage: adb push collect.sh /data/local/tmp/
#        adb shell su -c 'sh /data/local/tmp/collect.sh'
# Output: /sdcard/pja110-snapshot.txt and /sdcard/pja110-fdt.dtb
OUT=/sdcard/pja110-snapshot.txt
FDT=/sdcard/pja110-fdt.dtb
: > "$OUT"
say() { echo "$@" >> "$OUT"; }
sec() { echo "" >> "$OUT"; echo "===== $* =====" >> "$OUT"; }

sec identity
for p in ro.product.device ro.product.model ro.product.name ro.product.board \
         ro.build.display.id ro.build.version.release ro.build.version.sdk \
         ro.boot.hardware ro.boot.prjname ro.boot.project_name ro.boot.bootloader \
         ro.boot.dtbo_idx ro.boot.slot_suffix ro.boot.verifiedbootstate ro.boot.flash.locked; do
	say "$p=$(getprop $p)"
done
say "uname=$(uname -a)"
say "version=$(cat /proc/version)"
say "cmdline=$(cat /proc/cmdline)"

sec devicetree
for f in model compatible; do
	say "--- $f"
	cat "/proc/device-tree/$f" >> "$OUT" 2>/dev/null
	echo "" >> "$OUT"
done
say "--- chosen/bootargs"
cat /proc/device-tree/chosen/bootargs >> "$OUT" 2>/dev/null
echo "" >> "$OUT"
say "--- reserved-memory children"
ls /proc/device-tree/reserved-memory >> "$OUT" 2>/dev/null

sec fdt
if [ -r /sys/firmware/fdt ]; then
	cp /sys/firmware/fdt "$FDT" 2>/dev/null || cat /sys/firmware/fdt > "$FDT"
	say "fdt -> $FDT ($(stat -c %s "$FDT" 2>/dev/null) bytes)"
else
	say "/sys/firmware/fdt not readable"
fi

sec ramoops
R=/proc/device-tree/reserved-memory/ramoops_region
if [ -d "$R" ]; then
	for f in reg size pmsg-size console-size record-size ftrace-size mem-type alloc-ranges; do
		[ -e "$R/$f" ] || continue
		say "--- $f (raw cells)"
		od -An -tx4 "$R/$f" >> "$OUT" 2>/dev/null
	done
else
	say "ramoops_region: absent"
fi
say "--- pstore files"
ls -l /sys/fs/pstore >> "$OUT" 2>/dev/null
for f in /sys/fs/pstore/console-ramoops-0 /sys/fs/pstore/dmesg-ramoops-0 /sys/fs/pstore/pmsg-ramoops-0; do
	[ -f "$f" ] && { say "--- tail $f"; tail -n 120 "$f" >> "$OUT" 2>/dev/null; }
done

sec boot-image-header
for img in /sdcard/boot.img /sdcard/stock-boot.img; do
	[ -f "$img" ] && { say "found $img ($(stat -c %s "$img") bytes)"; }
done

sec partitions
ls -l /dev/block/by-name >> "$OUT" 2>/dev/null

sec modules
say "vendor_dlkm:"
ls /vendor/lib/modules >> "$OUT" 2>/dev/null
say "system_dlkm:"
ls /system/lib/modules >> "$OUT" 2>/dev/null

sec dmesg-tail
dmesg | tail -n 300 >> "$OUT" 2>/dev/null

echo "written: $OUT"
echo "fdt: $FDT"
