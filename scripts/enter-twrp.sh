#!/usr/bin/env bash
# Enter TWRP on Motorola xpeng (recovery-as-boot / header v3).
#
# Plain `fastboot boot boot.img` works: first_stage ForceNormalBoot returns
# false when /twres is present (TWRP ramdisk), so force_normal_boot=1 from the
# bootloader no longer drops into Android.
#
# Do NOT `flash boot` for daily use until dual-boot (Android from TWRP boot) works.
#
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BOOT="${BOOT_IMG:-$HOME/android/twrp-16.0/out/target/product/xpeng/boot.img}"
VB_STOCK="$ROOT/prebuilt/vendor_boot_stock.img"

usage() {
  echo "Usage: $0 {boot|restore-vendor_boot|recovery-UNSAFE}"
  echo "  boot                 fastboot boot TWRP (no vendor_boot flash needed)"
  echo "  restore-vendor_boot  flash stock vendor_boot only (if you previously patched it)"
  echo "  recovery-UNSAFE      flash boot + reboot recovery (breaks normal Android boot)"
  exit 1
}

[[ $# -ge 1 ]] || usage
[[ -f "$BOOT" ]] || { echo "missing boot.img: $BOOT"; exit 1; }

case "$1" in
  boot|fastboot-boot)
    echo "fastboot boot $BOOT"
    fastboot boot "$BOOT"
    ;;
  restore-vendor_boot)
    [[ -f "$VB_STOCK" ]] || { echo "missing $VB_STOCK"; exit 1; }
    fastboot flash vendor_boot "$VB_STOCK"
    echo "Stock vendor_boot restored."
    ;;
  recovery-UNSAFE)
    echo "WARNING: Flashed TWRP boot cannot boot Android (no dual-boot yet)."
    fastboot flash boot "$BOOT"
    fastboot reboot recovery
    ;;
  *) usage ;;
esac
