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
  "$ROOT"/system/bin/fsckexfat \
  "$ROOT"/system/bin/memeater \
  "$ROOT"/system/bin/charger \
  "$ROOT"/system/bin/keystore_cli_v2 \
  "$ROOT"/system/bin/avbctl \
  "$ROOT"/system/bin/awk \
  "$ROOT"/system/bin/bc \
  "$ROOT"/system/bin/e2fsdroid \
  "$ROOT"/system/bin/sgdisk \
  "$ROOT"/system/bin/simg2img \
  "$ROOT"/system/bin/ozip_decrypt \
  "$ROOT"/system/bin/bu \
  "$ROOT"/system/bin/linker_asan64 \
  "$ROOT"/system/bin/linker_hwasan64

rm -f \
  "$ROOT"/system/lib64/libclang_rt.ubsan_standalone-aarch64-android.so

# A14 adbd is self-contained; these extras are pulled into recovery but unused.
rm -f \
  "$ROOT"/system/lib64/libadbd_services.so \
  "$ROOT"/system/lib64/libadbconnection_server.so \
  "$ROOT"/system/lib64/libadb_protos.so \
  "$ROOT"/system/lib64/libapp_processes_protos_lite.so \
  "$ROOT"/system/lib64/libadbd.so \
  "$ROOT"/system/lib64/libadb_tls_connection.so \
  "$ROOT"/system/lib64/libadb_crypto.so \
  "$ROOT"/system/lib64/libadb_sysdeps.so \
  "$ROOT"/system/lib64/libmdnssd.so \
  "$ROOT"/system/lib64/libcutils_sockets.so \
  "$ROOT"/system/lib64/libsoftkeymasterdevice.so \
  "$ROOT"/system/lib64/libservices.so \
  "$ROOT"/system/lib64/libnetd_client.so \
  "$ROOT"/system/lib64/libutilscallstack.so \
  "$ROOT"/system/lib64/libgatekeeper.so \
  "$ROOT"/system/lib64/libext2_profile.so \
  "$ROOT"/system/lib64/libandroid_runtime_lazy.so \
  "$ROOT"/system/lib64/libnos_transport.so \
  "$ROOT"/system/lib64/libnos_datagram.so \
  "$ROOT"/system/lib64/libhidltransport.so \
  "$ROOT"/system/lib64/android.system.suspend@1.0.so \
  "$ROOT"/system/lib64/android.system.wifi.keystore@1.0.so \
  "$ROOT"/system/lib64/android.hidl.token@1.0.so \
  "$ROOT"/system/lib64/android.frameworks.stats-V1-ndk.so \
  "$ROOT"/system/lib64/android.hardware.vibrator@1.0.so \
  "$ROOT"/system/lib64/android.hardware.vibrator@1.1.so \
  "$ROOT"/system/lib64/android.hardware.vibrator@1.2.so \
  "$ROOT"/system/lib64/android.hardware.vibrator-V1-cpp.so \
  "$ROOT"/system/lib64/android.hardware.vibrator-V1-ndk.so \
  "$ROOT"/system/lib64/android.hardware.vibrator-V2-cpp.so

find "$ROOT/system" -name 'me.twrp.twrpapp.apk' -delete
rm -f "$ROOT/system/etc/permissions/privapp-permissions-twrpapp.xml"
rm -f "$ROOT"/system/bin/privapp-permissions-twrpapp.xml

if [[ -d "$DT_ROOT/vendor/lib/modules" ]]; then
  rm -rf "$ROOT/vendor/lib/modules"
  mkdir -p "$ROOT/vendor/lib"
  cp -a "$DT_ROOT/vendor/lib/modules" "$ROOT/vendor/lib/"
fi
if [[ -d "$DT_ROOT/vendor/firmware" ]]; then
  rm -rf "$ROOT/vendor/firmware"
  cp -a "$DT_ROOT/vendor/firmware" "$ROOT/vendor/"
fi

# Extra strip pass (build already strips most targets; cheap remaining gains).
STRIP_BIN=""
if [[ -n "${ANDROID_BUILD_TOP:-}" ]]; then
  STRIP_BIN="$(ls "${ANDROID_BUILD_TOP}"/prebuilts/clang/host/linux-x86/clang-*/bin/llvm-strip 2>/dev/null | tail -1 || true)"
fi
if [[ -z "$STRIP_BIN" && -n "${OUT:-}" ]]; then
  _top="$(cd "${OUT}/../../.." && pwd)"
  STRIP_BIN="$(ls "${_top}"/prebuilts/clang/host/linux-x86/clang-*/bin/llvm-strip 2>/dev/null | tail -1 || true)"
fi
if [[ -z "$STRIP_BIN" ]]; then
  STRIP_BIN="$(command -v llvm-strip 2>/dev/null || true)"
fi
if [[ -n "$STRIP_BIN" && -x "$STRIP_BIN" ]]; then
  find "$ROOT" -type f ! -type l -size +1k -print0 \
    | xargs -0 -r -n 40 "$STRIP_BIN" --strip-all 2>/dev/null || true
fi

echo "xpeng slim-ramdisk: $(du -sh "$ROOT" | awk '{print $1}')"
