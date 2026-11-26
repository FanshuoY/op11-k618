# PJA110 / xigua device package

This directory is the active device package for the **OnePlus Ace 2 Pro (PJA110 / OP5943L1)**, Qualcomm **SM8550 / kalama**, OnePlus project **22851**, device code **xigua**, Android **15 / ColorOS 15**, stock kernel **5.15.167**.

`device/salami` is the old OnePlus 11 package and is **not** used by the current build.

## What is here

| File | Purpose |
|---|---|
| `fdt.dtb` | PJA110 live FDT, captured from `/sys/firmware/fdt`, sanitized and patched for the 6.18 diagnostic image |
| `cmdline.txt` | Boot-header cmdline and the same string written into the FDT `/chosen/bootargs` |
| `M0-test.md` | `fastboot boot` procedure and what to report back |
| `collect.sh` | Re-collect the device snapshot without guessing any address |

## FDT provenance and edits

The DTB is **not** a generic SM8550 DTB. It is the exact FDT the PJA110 bootloader handed to the stock 5.15 kernel, so it contains the panel, touch, PMIC, charger, UFS and reserved-memory layout of this unit.

Three in-place edits were made (property lengths are unchanged, so the FDT structure is still valid):

1. `/chosen/bootargs` replaced with `cmdline.txt`. The stock string contained `oplusboot.serialno=69ac6bd0`, `init=/init` and `console=ttynull`; the serial number is gone and the kernel gets the diagnostic cmdline instead.
2. `/chosen/linux,initrd-start` and `/chosen/linux,initrd-end` set to zero. The live FDT still pointed at the stock `init_boot` ramdisk (`0xb6af1000`–`0xb7ffe438`); leaving those values would make 6.18 try to unpack stale memory.
3. `/chosen/kaslr-seed` is already zero; it is left as is.

The stock `/reserved-memory/ramoops_region` node has **no `reg`**; it only has `alloc-ranges`, `size = 0x240000`, `pmsg-size = 0x200000`, `console-size = 0x40000`, `mem-type = 2`. Do not expect that node alone to give the upstream `ramoops` driver a fixed resource. The diagnostic image therefore passes the ramoops layout on the kernel cmdline, which creates the driver's dummy platform device.

## Why `0xe2000000`

The live FDT memory map starts the low RAM bank at `0xe1bb0000`. The only reserved region in that area is `hwfence-shmem` at `0xe6440000`; everything between `0xe1bb0000` and `0xe6440000` that is not explicitly reserved is free. `0xe2000000` + `0x240000` ends at `0xe2240000`, well below `hwfence-shmem`.

This is a **candidate**, not a stock-verified answer. If the first boot still produces no pstore, the next check is whether the reserved-memory allocator grabbed `0xe2000000` for the un-`reg`ed `ramoops_region`, and the address will be moved.

## Stock boot image facts

Read from `boot_a` (`/dev/block/sde13`) on this unit:

- partition size: `201326592` bytes (192 MiB)
- header version: 4
- `kernel_size`: `55437824`
- `ramdisk_size`: 0
- kernel payload: raw arm64 `Image`, starts with `MZ`
- AVB footer: `original_image_size = 55443456`, `vbmeta_offset = 55443456`, `vbmeta_size = 2432`
- AVB hash descriptor: `partition_name = boot`, `hash_algorithm = sha256`, `salt = d716067806deff6786d8c63c2f6f9c4d`
- `os_version` field decodes to **13.0.0**, patch level **2025-11**

The diagnostic packer uses the same header version, the same `os_version` / patch level, and the same salt. The AVB footer is added with `--algorithm NONE`, exactly like the known-working OnePlus 11 mainline package, even though AVB is already disabled on this unit. If the bootloader still rejects the image, the exact `fastboot` error matters.

## M0.2 image composition

```
Image (ACK 6.18.32, arm64 GKI)
  + fdt.dtb (742905 bytes, patched)
  -> mkbootimg header v4, os_version 13.0.0 / 2025-11
  -> avbtool add_hash_footer, partition_size 201326592, algorithm NONE
```

No vendor modules and no initramfs yet. This is deliberate: the first question is whether the bootloader accepts the image and whether the kernel reaches its own console/pstore setup. If it panics at `init=/init`, that panic is itself useful and should land in `console-ramoops-0`.
