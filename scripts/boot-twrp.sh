#!/usr/bin/env bash
# Temporary-boot TWRP for xpeng (header v3 / recovery-as-boot).
# Requires twrpfastboot=1 or first_stage treats force_normal_boot as "boot Android".
set -euo pipefail
IMG="${1:-$HOME/android/twrp-16.0/out/target/product/xpeng/boot.img}"
if [[ ! -f "$IMG" ]]; then
  echo "boot.img not found: $IMG" >&2
  exit 1
fi
exec fastboot boot --cmdline "twrpfastboot=1" "$IMG"
