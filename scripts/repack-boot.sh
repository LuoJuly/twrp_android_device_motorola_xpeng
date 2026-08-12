#!/usr/bin/env bash
# Repack out/target/product/xpeng/boot.img for Motokernel.
# Critical: use lz4 *legacy* frame (-l). Modern lz4 frames fail to decompress
# on this kernel → black screen / no TWRP UI.
set -euo pipefail
TOP="${ANDROID_BUILD_TOP:-$HOME/android/twrp-16.0}"
DT="${TOP}/device/motorola/xpeng"
OUT="${TOP}/out/target/product/xpeng"
HOST="${TOP}/out/host/linux-x86/bin"
ROOT="${OUT}/recovery/root"

bash "${DT}/recovery/slim-ramdisk.sh" "${ROOT}"
# Re-assert shell wrapper after strip pass
if [[ -f "${DT}/recovery/root/system/bin/update_engine_sideload.wrap" \
   && -f "${ROOT}/system/bin/update_engine_sideload.real" ]]; then
  cp -a "${DT}/recovery/root/system/bin/update_engine_sideload.wrap" \
    "${ROOT}/system/bin/update_engine_sideload"
  chmod 755 "${ROOT}/system/bin/update_engine_sideload"
fi

"${HOST}/mkbootfs" -d "${OUT}/system" "${ROOT}" > "${OUT}/ramdisk-recovery.cpio"
"${HOST}/lz4" -l -12 --favor-decSpeed -c "${OUT}/ramdisk-recovery.cpio" \
  > "${OUT}/ramdisk-recovery.img"

KERNEL="${OUT}/kernel"
[[ -f "${KERNEL}" ]] || KERNEL="${DT}/prebuilt/kernel"

CMDLINE='console=ttyMSM0,115200n8 androidboot.hardware=qcom androidboot.console=ttyMSM0 androidboot.memcg=1 lpm_levels.sleep_disabled=1 service_locator.enable=1 androidboot.usbcontroller=a600000.dwc3 swiotlb=0 loop.max_part=7 cgroup.memory=nokmem,nosocket pcie_ports=compat iptable_raw.raw_before_defrag=1 ip6table_raw.raw_before_defrag=1 firmware_class.path=/vendor/firmware_mnt/image androidboot.hab.product=xpeng'

"${HOST}/mkbootimg" \
  --header_version 3 \
  --pagesize 4096 \
  --base 0x00000000 \
  --kernel_offset 0x00008000 \
  --ramdisk_offset 0x01000000 \
  --tags_offset 0x00000100 \
  --os_version 16.0.0 \
  --os_patch_level 2099-12-31 \
  --cmdline "${CMDLINE}" \
  --kernel "${KERNEL}" \
  --ramdisk "${OUT}/ramdisk-recovery.img" \
  --output "${OUT}/boot.img.unsigned"

"${HOST}/avbtool" add_hash_footer \
  --image "${OUT}/boot.img.unsigned" \
  --partition_size 100663296 \
  --partition_name boot \
  --algorithm SHA256_RSA4096 \
  --key "${TOP}/external/avb/test/data/testkey_rsa4096.pem"

cp -f "${OUT}/boot.img.unsigned" "${OUT}/boot.img"
echo "Wrote ${OUT}/boot.img"
