#!/usr/bin/env bash
# Apply device-tree patches/ to a synced twrp-16.0 tree (bootable/recovery).
# Usage: ./scripts/apply-patches.sh [/path/to/twrp-16.0]
set -euo pipefail

DT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TWRP_ROOT="${1:-${TWRP_ROOT:-$HOME/android/twrp-16.0}}"
PATCH_DIR="$DT_ROOT/patches"
TARGET="$TWRP_ROOT/bootable/recovery"

if [[ ! -d "$TARGET" ]]; then
  echo "bootable/recovery not found under: $TWRP_ROOT" >&2
  echo "Pass the twrp-16.0 source root as argument." >&2
  exit 1
fi

if [[ ! -d "$PATCH_DIR" ]]; then
  echo "No patches/ directory in device tree." >&2
  exit 1
fi

shopt -s nullglob
patches=("$PATCH_DIR"/[0-9]*.patch)
if [[ ${#patches[@]} -eq 0 ]]; then
  echo "No numbered patches in $PATCH_DIR"
  exit 0
fi

echo "Applying ${#patches[@]} patch(es) to $TARGET"
for p in "${patches[@]}"; do
  echo "-> $(basename "$p")"
  # Prefer git apply (safer); fall back to patch -p1
  if git -C "$TARGET" apply --check "$p" >/dev/null 2>&1; then
    git -C "$TARGET" apply "$p"
  elif patch -d "$TARGET" -p1 --dry-run -i "$p" >/dev/null 2>&1; then
    patch -d "$TARGET" -p1 -i "$p"
  else
    echo "SKIP (does not apply cleanly on this twrp-16.0 revision): $(basename "$p")" >&2
  fi
done
echo "Done."
