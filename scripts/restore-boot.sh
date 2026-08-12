#!/usr/bin/env bash
# Unbrick xpeng after a bad TWRP boot flash — restore working boot (+ optional vendor_boot).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# Prefer the boot actually pulled from this phone (matches running build)
PHONE_BOOT="$ROOT/.extract/adb_pull_20260812_084902/images/boot.img"
LOS_BOOT="${HOME}/下载/boot_lineageos.img"
VB_STOCK="$ROOT/prebuilt/vendor_boot_stock.img"

echo "Put the phone in fastboot (Vol- + Power while bootlooping), USB connected."
echo "Waiting for fastboot device..."
fastboot wait-for-device

BOOT="$PHONE_BOOT"
if [[ ! -f "$BOOT" ]]; then
  BOOT="$LOS_BOOT"
fi
[[ -f "$BOOT" ]] || { echo "No restore boot.img found"; exit 1; }

echo "Flashing boot <- $BOOT"
fastboot flash boot "$BOOT"

if [[ -f "$VB_STOCK" ]]; then
  echo "Flashing vendor_boot (stock) <- $VB_STOCK"
  fastboot flash vendor_boot "$VB_STOCK"
fi

echo "Rebooting to system..."
fastboot reboot
echo "Done. If it still loops, try the other slot: fastboot set_active other && fastboot reboot"
