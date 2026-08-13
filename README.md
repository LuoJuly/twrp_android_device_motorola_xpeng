# TWRP device tree for Motorola xpeng (XT2175)

The Motorola G200 5G / Edge S30 (codenamed _"xpeng"_) TWRP device tree for Android 12.1 (twrp-12.1).

## Blobs

Blobs from stock ROM `android-12-release-S3RXC32.33-8-29`

## Kernel

Prebuilt kernel from stock ROM `5.4.302-s3rxc32.33-8-25-ReSukiSU`

## Compile

First repo init the twrp-12.1 tree:

```bash
mkdir ~/android/twrp-12.1
cd ~/android/twrp-12.1
repo init -u https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp.git -b twrp-12.1
mkdir -p .repo/local_manifests
```

Then add a local manifest (e.g. `.repo/local_manifests/xpeng.xml`):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<manifest>
  <project name="LuoJuly/twrp_android_device_motorola_xpeng"
           path="device/motorola/xpeng"
           remote="github"
           revision="android-12.1"/>
</manifest>
```

Sync sources:

```bash
repo sync
```

Build:

```bash
. build/envsetup.sh
export ALLOW_MISSING_DEPENDENCIES=true
lunch twrp_xpeng-eng
mka bootimage
```

Output: `out/target/product/xpeng/boot.img` (recovery-as-boot).

Notes:

- Decrypt keeps `PLATFORM_SECURITY_PATCH` / `VENDOR_SECURITY_PATCH` at `2099-12-31`.
- A/B zip sideload wraps `update_engine_sideload` so that forged `2099` SPL does not look like a security-patch downgrade (avoids BCB `--wipe_data` / powerwash). The wrapper prefers the on-device system/vendor SPL and falls back to `1970-01-01`.

Temporary boot (recommended first):

```bash
fastboot boot out/target/product/xpeng/boot.img
```
