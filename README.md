# PJA110 · Linux 6.18 (work in progress)

An **M0.2 scaffold** for a Linux 6.18 port on the **OnePlus Ace 2 Pro** (Snapdragon 8 Gen 2, **SM8550** / `kalama`, model **PJA110** / `OP5943L1`, OnePlus project **22851**, device code **xigua**), running **Android 15 / ColorOS 15** on the stock **5.15.167** kernel.

> **Status: M0.2 only.** This repository builds ACK 6.18 and a diagnostic boot image with the **PJA110 live FDT** appended and a valid AVB footer. It does **not** include vendor modules and does **not** boot Android userspace yet. Use only `fastboot boot`; do not flash partitions.

## What it builds

| Output | What it is |
|---|---|
| `dist/Image` | ACK `android17-6.18` @ `ff4a6c3b` (6.18.32), arm64 GKI, LLVM 22 |
| `dist/Image-dtb` | `Image` + `device/xigua/fdt.dtb` appended |
| `dist/fdt.dtb` | PJA110 live FDT, serial removed, bootargs replaced, stale initrd pointers zeroed |
| `dist/diag-nolayer.img` | Header-v4 boot image, 192 MiB partition size, AVB footer (`algorithm NONE`) |
| `dist/gki.config` | Exact config used |
| `dist/avb.txt` | `avbtool verify_image` output |
| `dist/build.log` | Build log |

The image uses the stock `vendor_boot` / `init_boot` / device tree **only as a packaging reference**. `fastboot boot` replaces the kernel for one boot; a normal reboot returns to the stock kernel.

## Why the first image failed

The first M0 image was a bare `Image` with no appended DTB, no AVB footer and no `ramoops` parameters. On the phone it returned to the first screen and `/sys/fs/pstore` stayed `total 0`. The kernel itself could not be ruled in or out because the bootloader had no PJA110 FDT to hand it, and the image had no boot footer.

M0.2 fixes the packaging first:

1. **Appends the exact PJA110 live FDT** (`device/xigua/fdt.dtb`, 742905 bytes) to the `Image`.
2. **Replaces `/chosen/bootargs`** with the diagnostic cmdline and **zeroes `/chosen/linux,initrd-*`**, which otherwise pointed at stale stock `init_boot` memory.
3. **Adds a header-v4 AVB footer** with the PJA110 stock salt, 192 MiB partition size, and `os_version 13.0.0 / 2025-11`.
4. **Passes the ramoops layout on the cmdline** (`0xe2000000`, `0x240000`, console `0x40000`, pmsg `0x200000`, `mem-type=2`), because the stock DT node has no `reg`.

AVB is already disabled on this unit. The footer is kept because the stock image has one and the known-working OnePlus 11 mainline package uses the same `algorithm NONE` footer. If the bootloader still rejects the image, the exact `fastboot` error is the next data point.

## Run it

GitHub Actions → **build-m0** → **Run workflow**. The artifact is `pja110-k618-m0-<run>`.

```bash
adb reboot bootloader
fastboot devices
fastboot boot diag-nolayer.img
```

Follow [`device/xigua/M0-test.md`](device/xigua/M0-test.md) for the exact reporting steps. In short: after returning to stock, read `/sys/fs/pstore` and send `console-ramoops-0`.

## Device facts (verified on the connected unit)

- Model `PJA110` / `OP5943L1`; build `PJA110_15.0.0.861(CN01)`; Android **15**, SDK 35.
- `ro.product.board=kalama`, `ro.boot.prjname=22851`, `ro.boot.hardware=qcom`.
- Stock kernel `5.15.167-android13-8-o-01144-gd83a4482a19d`; slot `_a`.
- Panel `qcom,mdss_dsi_panel_AA536_P_3_A0001_dsc_cmd`; touch `synaptics-s3910`; NFC `xigua_nfc_sn110`; charger `oplus-chg-22851`; fingerprint `uff_sm8550`.
- `boot_a=/dev/block/sde13`, `init_boot_a=sde32`, `vendor_boot_a=sde24`, `dtbo_a=sde17`.
- Bootloader unlocked (`fastboot getvar unlocked` → `yes`); AVB disabled by the user.
- Stock `boot_a`: 201326592 bytes, header v4, kernel 55437824 bytes, no ramdisk, AVB footer; salt `d716067806deff6786d8c63c2f6f9c4d`.
- DT ramoops: size `0x240000`, pmsg `0x200000`, console `0x40000`, mem-type `2`, no fixed `reg`.
- OnePlusOSS branch for this device: `oneplus/sm8550_v_15.0.0_ace_2_pro` (Android 15) / `oneplus/sm8550_b_16.0.0_ace_2_pro` (Android 16).
- DT source root: `kernel_platform/qcom/proprietary/devicetree/oplus/` (`xigua-22851-kalama-overlay.dts`, `xigua_overlay_common.dtsi`, `kalama_overlay_common.dtsi`, `oplus_chg/oplus-chg-22851.dtsi`, `uff_sm8550.dtsi`, `sensor/xigua-sensor-22851.dtsi`, `nfc/xigua_nfc_sn110.dtsi`, `tp/xigua-oplus-tp-22851.dtsi`).

## Roadmap

| Stage | Goal |
|---|---|
| **M0.2** (this repo now) | Image + PJA110 FDT + AVB footer; prove `fastboot boot`; get pstore |
| M0.3 | If pstore is still empty: built-in initramfs marker, alternate ramoops address, UART |
| M1 | kalama SoC modules (clocks, pinctrl, interconnect, UPM, UFS, USB) |
| M2 | Display + touch |
| M3 | Full vendor module layer, boot to ColorOS |
| M4 | Camera / audio / NFC / fingerprint / charger |
| M5 | Power, thermal, scheduler (WALT) |

## Credits

- [`palazik/op13_kernel_6.18`](https://github.com/palazik/op13_kernel_6.18) — the OnePlus 6.6 → 6.18 port this scaffold follows.
- [`JiaqiLi404/android_kernel_618_for_sm8550`](https://github.com/JiaqiLi404/android_kernel_618_for_sm8550) — SM8550 5.15 → 6.18 reference.
- [`qingzhou704/oneplus11-mainline-linux`](https://github.com/qingzhou704/oneplus11-mainline-linux) — known-working salami boot-image packaging (appended DTB, built-in initramfs, AVB `NONE`, 192 MiB).
- [`OnePlusOSS`](https://github.com/OnePlusOSS) — PJA110 kernel, modules and device tree.
- Google — ACK, `mkbootimg`, `avbtool`.

## License

GPL-2.0, as the kernel sources it builds. See [`LICENSE`](LICENSE). `avbtool.py` is fetched at build time under its own Apache-2.0 license.
