# M0 测试步骤（一加 11 / PHB110）

> 只做 `fastboot boot`，不刷任何分区。掉电/长按电源+音量上可回到原系统。

## 1. 拿镜像

GitHub Actions → `build-m0` → 最新一次成功的 run → Artifacts → `op11-k618-m0-<run>`。解压后得到 `diag-nolayer.img`。

## 2. 进 bootloader

```bash
adb reboot bootloader
fastboot devices
```

## 3. 临时启动

```bash
fastboot boot diag-nolayer.img
```

- 若提示 `FAILED (remote: 'Boot image is not signed')` 或直接拒绝：说明这台机器的 bootloader 不接受未签名 boot，M0 的 `fastboot boot` 路线要改用 EDL/签名单刷方案，先停下，不要 `fastboot flash`。
- 若命令返回 `OKAY` 后黑屏/重启循环：长按电源+音量上 10–15 秒回到 bootloader，再 `fastboot reboot` 回系统。

## 4. 取日志

不管启动成功还是失败，回到原系统后（root）：

```bash
adb shell su -c 'ls -l /sys/fs/pstore'
adb shell su -c 'cat /sys/fs/pstore/console-ramoops-0' > diag.log
adb shell su -c 'cat /sys/fs/pstore/dmesg-ramoops-0' >> diag.log
```

把 `diag.log` 发回来。`console-ramoops-0` 里能看到 6.18 的版本号、`Booting Linux`、DT 解析、`Run /init` 或 panic 原因，这是判断 M0 是否成功的关键。

## 5. 顺手采集设备常量

```bash
adb push device/salami/collect.sh /data/local/tmp/
adb shell su -c 'sh /data/local/tmp/collect.sh'
adb pull /sdcard/op11-snapshot.txt
```

`op11-snapshot.txt` 里的 `ramoops_region/reg` 是后续 6.18 设备树/CMD 必须用的真实地址，不能猜。
