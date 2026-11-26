# OnePlus 11 · Linux 6.18 (work in progress)

An **M0 scaffold** for a Linux 6.18 port on the **OnePlus 11** (Snapdragon 8 Gen 2, **SM8550** / `salami`, model **PHB110**), running **ColorOS 16 / Android 16** on the stock **5.15.197** kernel.

> **Status: M0 only.** This repository currently builds a bare ACK 6.18 kernel and a diagnostic boot image. It does **not** boot a phone yet, and it does **not** include vendor modules. Do not flash anything; only use `fastboot boot`.

## What it builds

| Output | What it is |
|---|---|
| `dist/Image` | ACK `android17-6.18` @ `ff4a6c3b` (6.18.32), arm64 GKI, LLVM 22 |
| `dist/diag-nolayer.img` | The same `Image` packed as a boot header v4 image, **no vendor modules**, for a `fastboot boot` smoke test |
| `dist/gki.config` | The exact config used |
| `dist/build.log` | Build log |

The diagnostic image uses the stock `vendor_boot` / `init_boot` / device tree from the phone: `fastboot boot` replaces only the kernel for one boot, and a normal reboot returns to the stock kernel.

## Why M0 first

The 6.18 kernel and the SM8550 SoC support are two separate problems. M0 only answers:

1. Does the PHB110 bootloader accept a 6.18 `Image` with header v4?
2. Does the kernel reach first-stage init with the stock device tree?
3. What is the real `ramoops` address / layout on this phone?

Only after those are answered is it worth building SoC / techpack / vendor modules.

## Run it

GitHub Actions → **build-m0** → **Run workflow**. The artifact contains the files above.

```bash
adb reboot bootloader
fastboot boot diag-nolayer.img
```

If it hangs, reset with **Power + Volume Up** (10–15 s). Read the log from the stock system (root):

```bash
adb shell su -c 'cat /sys/fs/pstore/console-ramoops*' > diag.log
```

> The current diagnostic image has **no `ramoops` parameters** yet. Until the real address is read from the phone's live device tree, a hang before `adb` is a black box. See `device/salami/README.md`.

## Device facts (verified from OnePlusOSS, 2026-11-26)

- Branch: `oneplus/sm8550_b_16.0.0_oneplus_11` → ColorOS 16.0.5.1301, kernel **5.15.197**.
- Panel: Samsung `AMB670YF07` 1440×3216 DSC cmd (several panel variants in the DT).
- Touch: Synaptics `S3908` active (`qcom,i2c-touch-active = "synaptics-s3908"`), plus a Goodix Berlin node.
- Charger: `oplus-chg-22811.dtsi`. NFC: `salami_nfc_es2.dtsi`. Fingerprint: UFF.
- DT `ramoops`: `size = 0x240000`, `pmsg-size = 0x200000`, `console-size = 0x40000`; the `reg` is filled by the bootloader, so it must be read from the live DT.

## Roadmap

| Stage | Goal |
|---|---|
| **M0** (this repo now) | Bare 6.18 + stock DT; prove `fastboot boot`; read ramoops |
| M1 | kalama SoC modules (clocks, pinctrl, interconnect, UPM, UFS, USB) |
| M2 | Display + touch |
| M3 | Full vendor module layer, boot to ColorOS |
| M4 | Camera / audio / NFC / fingerprint / charger |
| M5 | Power, thermal, scheduler (WALT) |

## Credits

- [`palazik/op13_kernel_6.18`](https://github.com/palazik/op13_kernel_6.18) — the OnePlus 6.6 → 6.18 port this scaffold follows (boot image method, GKI config, `fastboot boot` workflow).
- [`JiaqiLi404/android_kernel_618_for_sm8550`](https://github.com/JiaqiLi404/android_kernel_618_for_sm8550) — the SM8550 5.15 → 6.18 reference (`soc-sm8550.patch`, kalama support, 5.15 shims).
- [`OnePlusOSS`](https://github.com/OnePlusOSS) — the PHB110 kernel, modules and device tree.
- Google — ACK and `mkbootimg`.

## License

GPL-2.0, as the kernel sources it builds. See [`LICENSE`](LICENSE).
