#!/usr/bin/env bash
# Late slim of TARGET_RECOVERY_ROOT_OUT (run after all recovery installs).
# Prefer $1; else $OUT/recovery/root; else out/target/product/*/recovery/root.
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
rm -f \
  "$ROOT"/system/bin/magiskboot \
  "$ROOT"/system/bin/logd \
  "$ROOT"/system/bin/logcat \
  "$ROOT"/system/bin/exfat-fuse \
  "$ROOT"/system/bin/mkexfatfs \
  "$ROOT"/system/bin/fsckexfat

rm -f \
  "$ROOT"/system/lib64/libclang_rt.ubsan_standalone-aarch64-android.so

find "$ROOT/system" -name 'me.twrp.twrpapp.apk' -delete
rm -f "$ROOT/system/etc/permissions/privapp-permissions-twrpapp.xml"

if [[ -d "$DT_ROOT/vendor/lib/modules" ]]; then
  rm -rf "$ROOT/vendor/lib/modules"
  mkdir -p "$ROOT/vendor/lib"
  cp -a "$DT_ROOT/vendor/lib/modules" "$ROOT/vendor/lib/"
fi
if [[ -d "$DT_ROOT/vendor/firmware" ]]; then
  rm -rf "$ROOT/vendor/firmware"
  cp -a "$DT_ROOT/vendor/firmware" "$ROOT/vendor/"
fi

# Wrap update_engine_sideload so forged 2099 SPL (Keymaster decrypt) does not
# look like an OTA security-patch downgrade → BCB --wipe_data / powerwash.
# Same approach as android-16.0: prefer on-device system/vendor SPL.
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

echo "xpeng slim-ramdisk: $(du -sh "$ROOT" | awk '{print $1}')"
