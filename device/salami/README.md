# device/salami

Placeholders for the OnePlus 11 (PHB110 / salami) device pack. Nothing here is needed for the M0 diagnostic image except `cmdline.txt`.

## Values to read from the phone (root)

```bash
adb shell su -c 'cat /proc/device-tree/model'
adb shell su -c 'cat /proc/device-tree/compatible'
adb shell su -c 'cat /proc/device-tree/reserved-memory/ramoops_region/reg'
adb shell su -c 'cat /proc/cmdline'
```

The `ramoops_region/reg` value is a sequence of 32-bit cells (`<address-high address-low size-high size-low>`); it is what the stock kernel actually uses. The DT source only has `alloc-ranges`, `size = 0x240000`, `pmsg-size = 0x200000`, `console-size = 0x40000`, so the address cannot be guessed.

## Values to extract from the stock OTA

- `boot.img` header: `unpack_bootimg --boot_img boot.img` (header version, page size, cmdline, OS version/patch).
- `vendor_dlkm/lib/modules/*/modules.load`, `modules.blocklist`.
- `system_dlkm` module lists.
- The stock `vendor_boot` / `init_boot` ramdisks (for the later module layer).

These are proprietary binaries; do not commit them unless you know the redistribution terms. Put only the extracted text lists and constants in this directory.
