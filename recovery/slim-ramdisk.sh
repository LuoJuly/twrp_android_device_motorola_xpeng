#!/usr/bin/env bash
# Late slim of TARGET_RECOVERY_ROOT_OUT (run after all recovery installs).
# Prefer $1; else $OUT/recovery/root; else out/target/product/*/recovery/root.
#
# Motokernel rejects oversized initramfs ("Could not decompress" / "RAMDISK: image
# too big"). LOS boot ramdisk ~20MB compressed / ~40MB unpacked; keep TWRP closer.
set -euo pipefail
ROOT=""
if [[ -n "${1:-}" && -d "${1}" ]]; then
  ROOT="$1"
elif [[ -n "${OUT:-}" && -d "${OUT}/recovery/root" ]]; then
  ROOT="${OUT}/recovery/root"
elif [[ -d out/target/product/xpeng/recovery/root ]]; then
  ROOT="out/target/product/xpeng/recovery/root"
else
  echo "slim-ramdisk: recovery root not found (arg='${1:-}' OUT='${OUT:-}' cwd=$PWD)" >&2
  exit 1
fi
DT_ROOT="$(cd "$(dirname "$0")/root" && pwd)"

mkdir -p "$ROOT/twres/languages" "$ROOT/twres/fonts"
cp -f "$DT_ROOT/twres/languages/en.xml" "$ROOT/twres/languages/"
cp -f "$DT_ROOT/twres/languages/zh_CN.xml" "$ROOT/twres/languages/"
cp -f "$DT_ROOT/twres/fonts/DroidSansFallback.ttf" "$ROOT/twres/fonts/"
find "$ROOT/twres/languages" -type f -name '*.xml' ! -name 'en.xml' ! -name 'zh_CN.xml' -delete
find "$ROOT/twres/fonts" -type f \( -name 'NotoSans*.ttf' -o -name 'Sinhala.ttf' -o -name '*.full' \) -delete
# Drop unused theme fonts / license / editor backups; keep subset Fallback + stock Roboto/Mono.
rm -f "$ROOT"/twres/fonts/DroidSansFallback.ttf.full \
  "$ROOT"/twres/fonts/OFL.txt
# Never ship backup/editor leftovers into the final cpio (fonts-src stays outside recovery/root).
find "$ROOT" -type f \( \
  -name '*.full' -o -name '*.bak' -o -name '*.orig' -o -name '*.old' \
  -o -name '*~' -o -name '*.swp' -o -name '*.tmp' -o -name '*.backup' \
\) -delete
# Build-time file list is not needed at runtime (~20KiB).
rm -f "$ROOT"/ramdisk-files.txt

rm -f \
  "$ROOT"/res/images/wipe_data_menu_header_text.png \
  "$ROOT"/res/images/wipe_data_confirmation_text.png \
  "$ROOT"/res/images/installing_security_text.png \
  "$ROOT"/res/images/installing_text.png \
  "$ROOT"/res/images/factory_data_reset_text.png \
  "$ROOT"/res/images/no_command_text.png \
  "$ROOT"/res/images/try_again_text.png \
  "$ROOT"/res/images/erasing_text.png \
  "$ROOT"/res/images/cancel_wipe_data_text.png \
  "$ROOT"/res/images/error_text.png \
  "$ROOT"/res/images/loop*.png

# Keep orscmd (installs as system/bin/twrp) and zip (same as main).
# Keep update_engine_sideload — A/B Lineage signed zips require it to flash the
# inactive slot (TWRP execs /system/bin/update_engine_sideload).
# Drop update_verifier + fastbootd for Motokernel ramdisk budget.
# Keep minadbd — TWRP ADB Sideload UI forks /system/bin/minadbd (not adbd).
rm -f \
  "$ROOT"/system/bin/magiskboot \
  "$ROOT"/system/bin/logd \
  "$ROOT"/system/bin/logcat \
  "$ROOT"/system/bin/exfat-fuse \
  "$ROOT"/system/bin/mkexfatfs \
  "$ROOT"/system/bin/fsckexfat \
  "$ROOT"/system/bin/ttyd \
  "$ROOT"/system/bin/microhttpd \
  "$ROOT"/system/bin/update_verifier \
  "$ROOT"/system/bin/fastbootd

# Wrap update_engine_sideload so forged 2099 SPL (Keymaster decrypt) does not
# look like an OTA security-patch downgrade → BCB --wipe_data / powerwash.
UE="$ROOT/system/bin/update_engine_sideload"
WRAP="$DT_ROOT/system/bin/update_engine_sideload.wrap"
if [[ -f "$UE" && -f "$WRAP" ]]; then
  if [[ ! -f "$ROOT/system/bin/update_engine_sideload.real" ]]; then
    mv "$UE" "$ROOT/system/bin/update_engine_sideload.real"
  else
    rm -f "$UE"
  fi
  cp -f "$WRAP" "$UE"
  chmod 0755 "$UE" "$ROOT/system/bin/update_engine_sideload.real"
  echo "xpeng slim-ramdisk: installed update_engine_sideload SPL wrapper"
fi

# BootControl for update_engine: AIDL recovery HAL (no /vendor/lib64/hw overlay).
mkdir -p "$ROOT/system/etc/init" "$ROOT/system/etc/vintf/manifest" "$ROOT/system/bin/hw"
if [[ -f "$DT_ROOT/system/etc/recovery.fstab.default" ]]; then
  cp -f "$DT_ROOT/system/etc/recovery.fstab.default" "$ROOT/system/etc/recovery.fstab.default"
fi
if [[ -f "$DT_ROOT/system/etc/vintf/manifest/boot-service.qti.xml" ]]; then
  cp -f "$DT_ROOT/system/etc/vintf/manifest/boot-service.qti.xml" \
    "$ROOT/system/etc/vintf/manifest/boot-service.qti.xml"
fi
if [[ -f "$DT_ROOT/system/etc/init/android.hardware.boot-service.qti.recovery.rc" ]]; then
  cp -f "$DT_ROOT/system/etc/init/android.hardware.boot-service.qti.recovery.rc" \
    "$ROOT/system/etc/init/android.hardware.boot-service.qti.recovery.rc"
fi
# TWRP still copies HIDL boot-hal-1-2; drop it so nothing mmaps vendor HALs.
rm -f \
  "$ROOT"/system/etc/init/android.hardware.boot@1.0-service.rc \
  "$ROOT"/system/etc/init/android.hardware.boot@1.1-service.rc \
  "$ROOT"/system/etc/init/android.hardware.boot@1.2-service.rc \
  "$ROOT"/system/etc/vintf/manifest/android.hardware.boot@1.0.xml \
  "$ROOT"/system/etc/vintf/manifest/android.hardware.boot@1.1.xml \
  "$ROOT"/system/etc/vintf/manifest/android.hardware.boot@1.2.xml \
  "$ROOT"/system/bin/android.hardware.boot@1.0-service \
  "$ROOT"/system/bin/android.hardware.boot@1.1-service \
  "$ROOT"/system/bin/android.hardware.boot@1.2-service \
  "$ROOT"/vendor/bin/hw/android.hardware.boot@1.0-service \
  "$ROOT"/vendor/bin/hw/android.hardware.boot@1.1-service \
  "$ROOT"/vendor/bin/hw/android.hardware.boot@1.2-service
rm -f \
  "$ROOT"/vendor/lib64/hw/android.hardware.boot@1.0-impl-1.2.so \
  "$ROOT"/vendor/lib64/hw/android.hardware.boot@1.0-impl-1.2-qti.so \
  "$ROOT"/system/lib64/hw/android.hardware.boot@1.0-impl-1.2.so \
  "$ROOT"/system/lib64/hw/android.hardware.boot@1.0-impl-1.2-qti.so
if [[ -f "$DT_ROOT/system/bin/preformatdata.sh" ]]; then
  cp -f "$DT_ROOT/system/bin/preformatdata.sh" "$ROOT/system/bin/preformatdata.sh"
  chmod 0755 "$ROOT/system/bin/preformatdata.sh"
fi
if [[ -x "$ROOT/system/bin/hw/android.hardware.boot-service.qti.recovery" ]]; then
  echo "xpeng slim-ramdisk: AIDL boot-service.qti.recovery present"
else
  echo "xpeng slim-ramdisk: WARNING missing android.hardware.boot-service.qti.recovery" >&2
fi

# Keep libperfetto_c.so — A16 servicemanager links it; without it Decrypt_Data
# hangs forever on the splash (servicemanager crash-loop).
rm -f \
  "$ROOT"/system/lib64/libclang_rt.ubsan_standalone-aarch64-android.so

rm -f "$ROOT"/system/etc/init/ttyd.rc \
  "$ROOT"/system/etc/init/microhttpd.rc \
  "$ROOT"/system/etc/microhttpd_webui/index.html
rm -rf "$ROOT"/system/etc/microhttpd_webui

find "$ROOT/system" -name 'me.twrp.twrpapp.apk' -delete
rm -f "$ROOT/system/etc/permissions/privapp-permissions-twrpapp.xml"

# Keep recovery modules except msm_drm.ko (~3.9MiB) — that stays on vendor_boot
# /lib/modules. Rest (~1.2MiB) matches vendor_boot 17-module list minus msm_drm
# (no mmi_sys_temp/utags; those are A12-only extras).
rm -rf "$ROOT/vendor/lib/modules.bak"
mkdir -p "$ROOT/vendor/lib"
if [[ -d "$DT_ROOT/vendor/lib/modules" ]]; then
  rm -rf "$ROOT/vendor/lib/modules"
  cp -a "$DT_ROOT/vendor/lib/modules" "$ROOT/vendor/lib/"
fi
# Always drop msm_drm from boot ramdisk if a copy slipped in.
rm -f "$ROOT/vendor/lib/modules/msm_drm.ko"
# Prefer DT modules; do not leave empty modules dir missing for init_thermal.
if [[ ! -d "$ROOT/vendor/lib/modules" ]]; then
  mkdir -p "$ROOT/vendor/lib/modules"
fi

if [[ -d "$DT_ROOT/vendor/firmware" ]]; then
  rm -rf "$ROOT/vendor/firmware"
  cp -a "$DT_ROOT/vendor/firmware" "$ROOT/vendor/"
fi
# Kernel request_firmware searches /lib/firmware after firmware_class.path.
# Do NOT rely on ramdisk /vendor/firmware: mounting super vendor hides it, and
# sideload/format can leave that inode EUCLEAN ("Structure needs cleaning").
mkdir -p "$ROOT/lib/firmware" "$ROOT/system/etc/firmware"
if [[ -d "$DT_ROOT/vendor/firmware" ]]; then
  cp -f "$DT_ROOT/vendor/firmware/"*.bin "$ROOT/lib/firmware/" 2>/dev/null || true
  cp -f "$DT_ROOT/vendor/firmware/"*.bin "$ROOT/system/etc/firmware/" 2>/dev/null || true
  # DT boot/resume name is tm_novatek_ts_fw.bin (panel-supplier=tm). MMI doreflash
  # uses novatek_ts-NT36675-*-xpeng.bin. Same payload; both names must exist or
  # first unblank loads the DT name, fails, and IRQs stay at 0.
  for src in "$ROOT/lib/firmware/"novatek_ts-*.bin; do
    [[ -f "$src" ]] || continue
    cp -f "$src" "$ROOT/lib/firmware/tm_novatek_ts_fw.bin"
    cp -f "$src" "$ROOT/system/etc/firmware/tm_novatek_ts_fw.bin"
    break
  done
fi

# QTI vibrator chain. After Format Data, super /vendor is unmapped and only
# ramdisk /vendor remains. vibratorOL.impl dlopens libqtivibratoreffectoffload
# which is not produced by this tree — copy the DT prebuilts explicitly.
mkdir -p "$ROOT/vendor/lib64"
for lib in \
  libqtivibratoreffect.so \
  libqtivibratoreffectoffload.so \
  libexpat.so \
  vendor.qti.hardware.vibrator.impl.so \
  vendor.qti.hardware.vibratorOL.impl.so \
  vendor.qti.hardware.vibratorSel.impl.so
do
  if [[ -f "$DT_ROOT/vendor/lib64/$lib" ]]; then
    cp -f "$DT_ROOT/vendor/lib64/$lib" "$ROOT/vendor/lib64/"
    chmod 0644 "$ROOT/vendor/lib64/$lib"
  fi
done
if [[ -f "$DT_ROOT/system/lib64/libexpat.so" ]]; then
  mkdir -p "$ROOT/system/lib64"
  cp -f "$DT_ROOT/system/lib64/libexpat.so" "$ROOT/system/lib64/"
  chmod 0644 "$ROOT/system/lib64/libexpat.so"
fi

# Strip ELF to cut unpacked size (lz4 ratio already high on unstripped).
STRIP_BIN=""
for c in \
  "${ANDROID_HOST_OUT:-}/bin/llvm-strip" \
  "${ANDROID_BUILD_TOP:-}/out/host/linux-x86/bin/llvm-strip" \
  /home/luojuly/android/twrp-16.0/out/host/linux-x86/bin/llvm-strip \
  llvm-strip strip
do
  if [[ -x "$c" ]] || command -v "$c" >/dev/null 2>&1; then
    STRIP_BIN=$(command -v "$c" 2>/dev/null || echo "$c")
    [[ -x "$STRIP_BIN" || -x "$c" ]] || continue
    [[ -x "$c" ]] && STRIP_BIN="$c"
    break
  fi
done
if [[ -n "$STRIP_BIN" && -x "$STRIP_BIN" ]]; then
  echo "xpeng slim-ramdisk: stripping with $STRIP_BIN"
  while IFS= read -r -d '' f; do
    # Skip scripts / non-ELF (e.g. update_engine_sideload wrapper).
    [[ "$(file -b "$f" 2>/dev/null || true)" == *ELF* ]] || continue
    "$STRIP_BIN" --strip-unneeded "$f" 2>/dev/null || true
  done < <(find "$ROOT" \( -type f -name '*.so' -o -type f -path '*/bin/*' -o -type f -path '*/sbin/*' \) -print0 2>/dev/null)
fi

echo "xpeng slim-ramdisk: $(du -sh "$ROOT" | awk '{print $1}')"
