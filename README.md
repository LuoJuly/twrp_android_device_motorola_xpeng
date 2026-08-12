# TWRP device tree for Motorola xpeng (XT2175)

The Motorola G200 5G / Edge S30 (codenamed _"xpeng"_) TWRP device tree for **twrp-14.1** (Android 14).

## Blobs

Blobs from stock ROM `android-12-release-S3RXC32.33-8-29`

## Kernel

Prebuilt kernel from stock ROM `5.4.302-s3rxc32.33-8-25-ReSukiSU`

## Compile

First repo init the twrp-14.1 tree:

```bash
mkdir ~/android/twrp-14.1
cd ~/android/twrp-14.1
repo init -u https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp.git -b twrp-14.1
mkdir -p .repo/local_manifests
```

Then add a local manifest (e.g. `.repo/local_manifests/xpeng.xml`):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<manifest>
  <project name="LuoJuly/twrp_android_device_motorola_xpeng"
           path="device/motorola/xpeng"
           remote="github"
           revision="android-14.1"/>
</manifest>
```

Sync sources:

```bash
repo sync
```

Build (JDK 17 recommended for Android 14):

```bash
. build/envsetup.sh
export ALLOW_MISSING_DEPENDENCIES=true
lunch twrp_xpeng-ap2a-eng
mka bootimage
```

Output: `out/target/product/xpeng/boot.img` (recovery-as-boot).

Temporary boot (recommended first):

```bash
fastboot boot out/target/product/xpeng/boot.img
```
