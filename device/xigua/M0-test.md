# M0.2 test — PJA110 / xigua

> Only `fastboot boot`. Do **not** `fastboot flash boot` for this test. A normal reboot returns to the stock 5.15 kernel.

## 1. Artifact

GitHub Actions → `build-m0` → latest successful run → artifact `pja110-k618-m0-<run>`. Unpack and keep:

- `diag-nolayer.img` — the image to boot
- `Image-dtb` — 6.18 `Image` with the PJA110 FDT appended
- `fdt.dtb` — the patched PJA110 FDT
- `gki.config` — exact kernel config

## 2. Boot it

```bash
adb devices
adb reboot bootloader
fastboot devices
fastboot boot diag-nolayer.img
```

Expected: `Sending 'boot.img' ... OKAY`, then `Booting ... OKAY`. The phone will show the first screen (OnePlus logo) and then either:

- **A)** the screen changes / animates: the kernel got past early boot; still no Android userspace, so treat this as a diagnostic success and read pstore.
- **B)** it stays on the first screen and reboots: capture the exact behavior and read pstore.
- **C)** `fastboot` returns `FAILED (remote: '...')`: copy the exact error text; do not retry with `flash`.

To leave a stuck boot: hold **Power + Volume Up** 10–15 s, then `fastboot reboot` or normal power-on.

## 3. Read pstore after returning to stock

```bash
adb shell su -c 'ls -l /sys/fs/pstore'
adb shell su -c 'cat /sys/fs/pstore/console-ramoops-0' > diag.log
adb shell su -c 'cat /sys/fs/pstore/dmesg-ramoops-0' >> diag.log 2>/dev/null
adb shell su -c 'cat /sys/fs/pstore/pmsg-ramoops-0' >> diag.log 2>/dev/null
```

Report:

1. the full `fastboot boot` output;
2. whether the phone reached the boot animation or rebooted at the first screen;
3. `ls -l /sys/fs/pstore` (is it still `total 0`?);
4. `diag.log`, or the first 200 lines of `console-ramoops-0` if it is large.

If `pstore` is still empty, the next image will add a built-in initramfs and a second ramoops address; this image is the cheapest way to find out whether the failure is before pstore registration or after it.
