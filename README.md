# TWRP for Motorola xpeng — LineageOS 23.2 / Android 16

设备：moto g200 5G / Edge S30（`xpeng`）  
目标：在 **LineageOS 23.2（Android 16 QPR2）** 上构建 TWRP（`twrp-16.0`）。

从 A12（`twrp-12.1`）设备树移植，按社区 Android 16 做法适配：

- 构建树：`TWRP-Test/platform_manifest_twrp_aosp` → `twrp-16.0`
- lunch：`twrp_xpeng-bp2a-eng`
- 解密：lahaina + **Keymaster 4.1**（QCOM FBE，不是新机 KeyMint/Weaver 路线）
- 内核/模块/密钥栈 blob：官方 LineageOS 23.2 nightly

## 资源来源

| 组件 | 来源 |
|------|------|
| `prebuilt/kernel` | LOS `boot.img`（`5.4.302-moto-g057847a8c116`） |
| recovery 模块 | LOS `vendor_boot` → `lib/modules`（vermagic 已对齐） |
| qseecomd / keymaster 4.1 / gatekeeper | LOS `vendor` |
| system 依赖库（libion 等） | LOS `system` |
| 分区 / 加密 flags | [LineageOS xpeng lineage-23.2](https://github.com/LineageOS/android_device_motorola_xpeng/tree/lineage-23.2) |

参考包：`lineage-23.2-20260808-nightly-xpeng`  
镜像：https://download.lineageos.org/devices/xpeng/builds

## 编译

```bash
mkdir -p ~/android/twrp-16.0 && cd ~/android/twrp-16.0
repo init --depth=1 -u https://github.com/TWRP-Test/platform_manifest_twrp_aosp.git -b twrp-16.0
repo sync -c -j$(nproc)

mkdir -p device/motorola
ln -sfn /path/to/twrp_android_device_motorola_xpeng_lineage device/motorola/xpeng

# 可选：应用 UI/MTP/haptics 等补丁（若与当前 twrp-16.0 对得上）
device/motorola/xpeng/scripts/apply-patches.sh "$PWD"

. build/envsetup.sh
export ALLOW_MISSING_DEPENDENCIES=true
lunch twrp_xpeng-bp2a-eng
mka bootimage
```

产物：`out/target/product/xpeng/boot.img`（recovery-as-boot）

> **Motorola 注意：** 不要用裸的 `fastboot boot boot.img`（即便加 `--cmdline`）。bootloader 仍会带 `force_normal_boot=1` 且常忽略 host cmdline，first_stage 会 SwitchRoot 进系统 → **黑屏后进系统**。

**推荐进入 TWRP：**

```bash
device/motorola/xpeng/scripts/enter-twrp.sh recovery
# 等价于：
# fastboot flash boot out/target/product/xpeng/boot.img
# fastboot reboot recovery
```

**若坚持临时 boot**（需改 vendor_boot cmdline 注入 `twrpfastboot=1`，测完务必还原）：

```bash
device/motorola/xpeng/scripts/enter-twrp.sh fastboot-boot
# 测完：
device/motorola/xpeng/scripts/enter-twrp.sh restore-vendor_boot
```

## 设计要点（相对 A12）

1. **构建**：`bp2a` lunch + `twrp_` 前缀（社区 A16 标准）
2. **分区**：LOS 23.2 `super=8589934592`，logical 为 ext4
3. **加密**：`wrappedkey_v0` + metadata；`PLATFORM_VERSION=99.87.36` + `prepdecrypt.setpatch`（沿用 A12 已验证路径）
4. **不引入** SM8850/KeyMint/Weaver 大补丁（本机仍是 Keymaster 4.1）
5. **触摸/电池**：`runatboot` + `init_thermal` + LOS 匹配模块

## 刷新 blob

```bash
# 从 download.lineageos.org 下载同日 boot / vendor_boot / dtbo 后：
./scripts/refresh-lineage-blobs.sh --boot boot.img --vendor-boot vendor_boot.img --dtbo dtbo.img
```

vendor 内 keymaster 等若大改，需再从 `vendor.img` 用 `debugfs` 抽出覆盖 `recovery/root`。

## 目录

```
BoardConfig.mk / device.mk / twrp_xpeng.mk
recovery.fstab / system.prop
prebuilt/{kernel,dtb,dtbo.img}
recovery/root/          # init、脚本、模块、解密/振动二进制
patches/                # bootable/recovery 可选补丁
scripts/apply-patches.sh
scripts/refresh-lineage-blobs.sh
```

## Build workarounds

Soong **cannot follow a symlink** for `device/motorola/xpeng` — rsync/copy the tree into the build workspace instead of `ln -s`.

Device-tree flags (already in this repo):

| Flag / file | Why |
|-------------|-----|
| `PRODUCT_CHECK_PREBUILT_MAX_PAGE_SIZE := false` (`device.mk`) | Prebuilt recovery bins (e.g. magiskboot) may be 4K-aligned; A16 build checks reject them otherwise |
| `PRODUCT_ENABLE_UFFD_GC := false` + `OVERRIDE_ENABLE_UFFD_GC := false` (`device.mk` / `twrp_xpeng.mk` / `BoardConfig.mk`) | Motokernel 5.4 has no UFFD GC; leave ART UFFD GC off |

TWRP **source** edits that lived only under `twrp-16.0` for the successful build (not saved as extra `patches/` unless noted):

| Location | What / why |
|----------|------------|
| `bootable/recovery/openaes/src/isaac/rand.{c,h}` + `oaes_lib.c` | ANSI C prototypes + rename `rand()` macro → `isaac_rand` so OpenAES builds under C23/clang (Android 16) |
| `bootable/recovery/prebuilt/Android.mk` | `task_profiles.json` copy fallback + `LOCAL_REQUIRED_MODULES += task_profiles.json` when `TARGET_OUT_ETC` copy is missing |
| `patches/0001`–`0002` (via `scripts/apply-patches.sh`) | Keep fstab Mount display names; quiet animation end-frame — applied in the successful build tree |
| `patches/0003`–`0004` | AIDL haptics / default MTP off — optional; may need refresh against current `bootable/recovery` |

Re-apply recovery-tree fixes after a clean `repo sync` of `bootable/recovery` before rebuilding.
