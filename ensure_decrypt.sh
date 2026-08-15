#!/system/bin/sh
# Bring up TEE/keymaster, then keystore2 (needed for metadata FBE decrypt).
export LD_LIBRARY_PATH=/vendor/lib64:/vendor/lib:/system/lib64:/system/lib:/sbin

mkdir -p /tmp/misc/keystore

i=0
while [ "$i" -lt 50 ]; do
  [ -e /dev/qseecom ] && [ -e /dev/ion ] && break
  i=$((i+1)); sleep 0.1
done

# qseecomd setuids to system(1000). RPMB/ION must be usable by system or
# keymaster upgrade fails (KEY_REQUIRES_UPGRADE then INCOMPATIBLE_BLOCK_MODE)
# with: rpmb_ufs: Unable to open /dev/0:0:0:49476 (error no: 13)
fix_tee_nodes() {
  for n in /dev/qseecom /dev/ion \
           /dev/0:0:0:49476 /dev/0:0:0:49456 /dev/0:0:0:49488 \
           /dev/ufs-bsg0; do
    [ -e "$n" ] || continue
    chown system system "$n" 2>/dev/null || true
    chmod 0660 "$n" 2>/dev/null || true
  done
}
fix_tee_nodes
# RPMB W-LUN can appear slightly later than qseecom
i=0
while [ "$i" -lt 30 ]; do
  [ -e /dev/0:0:0:49476 ] && break
  i=$((i+1)); sleep 0.1
done
fix_tee_nodes

# Force 4.1 only — TWRP may have set keymaster_ver=4.x from the manifest
setprop keymaster_ver 4.1

setprop crypto.ready 1

start qseecomd 2>/dev/null || true
sleep 0.5
if [ "$(getprop init.svc.qseecomd)" != "running" ] && [ -z "$(pidof qseecomd)" ]; then
  /system/bin/qseecomd &
  sleep 1
fi

i=0
while [ "$i" -lt 50 ]; do
  [ "$(getprop vendor.sys.listeners.registered)" = "true" ] && break
  [ "$(getprop sys.listeners.registered)" = "true" ] && break
  i=$((i+1)); sleep 0.1
done

# Prefer 4.1 only (also registers as 4.0). Dual 4.0+4.1 both as
# "default" can race and confuse km_compat / shared-secret negotiation.
stop keymaster-4-0-qti 2>/dev/null || true
stop keymaster-4-0 2>/dev/null || true
killall android.hardware.keymaster@4.0-service-qti 2>/dev/null || true
start keymaster-4-1-qti 2>/dev/null || true
start gatekeeper-1-0-qti 2>/dev/null || true
# AIDL bootctrl (Lineage-style). Binary lives in /system/bin/hw and only
# links system libs — do not overlay /vendor/lib64/hw (that blocked Format Data).
# Start here because on fs runs before class_start hal.
start vendor.boot-qti 2>/dev/null || true

if ! pidof android.hardware.keymaster@4.1-service-qti >/dev/null 2>&1; then
  /system/bin/android.hardware.keymaster@4.1-service-qti &
fi
if ! pidof android.hardware.gatekeeper@1.0-service-qti >/dev/null 2>&1; then
  /system/bin/android.hardware.gatekeeper@1.0-service-qti &
fi

# Wait until Keymaster HAL is published on hwbinder
i=0
while [ "$i" -lt 80 ]; do
  if lshal 2>/dev/null | grep -q "android.hardware.keymaster"; then
    break
  fi
  # lshal may be missing; fall back to process check + short settle
  if pidof android.hardware.keymaster@4.1-service-qti >/dev/null 2>&1 && [ "$i" -ge 20 ]; then
    break
  fi
  i=$((i+1)); sleep 0.1
done

# Allow keystore2.rc property trigger + explicit start (oneshot: retry a few times)
setprop keystore.ready 1
start_ks2() {
  start keystore2 2>/dev/null || true
  sleep 0.3
  if [ -z "$(pidof keystore2)" ] && [ -x /system/bin/keystore2 ]; then
    /system/bin/keystore2 /tmp/misc/keystore &
  fi
}
start_ks2

# Wait briefly for AIDL registration; retry start a few times if it dies early
i=0
retries=0
while [ "$i" -lt 80 ]; do
  if [ -n "$(pidof keystore2)" ]; then
    sleep 0.5
    # Still alive after settle?
    if [ -n "$(pidof keystore2)" ]; then
      break
    fi
  fi
  if [ "$retries" -lt 3 ]; then
    retries=$((retries+1))
    start_ks2
  fi
  i=$((i+1)); sleep 0.1
done

echo "ensure_decrypt: qsee=$(getprop init.svc.qseecomd) listeners=$(getprop vendor.sys.listeners.registered) km=$(pidof android.hardware.keymaster@4.1-service-qti) ks2=$(pidof keystore2) ks2svc=$(getprop init.svc.keystore2) crash=$(getprop keystore.crash_count)" > /dev/kmsg
exit 0
