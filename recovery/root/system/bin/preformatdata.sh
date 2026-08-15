#!/system/bin/sh
#
# Run before Format Data / dynamic-partition unmap.
# Vibrator (and leftover HIDL boot-hal) can keep /vendor busy so
# DestroyLogicalPartition(vendor_*) fails. AIDL boot HAL does not mmap
# /vendor/lib64/hw — do not kill vendor.boot-qti (update_engine needs it).
#
# Also release /data and the dm-default-key userdata mapper so make_f2fs
# can exclusive-open the raw userdata partition (sde25).
#
# Do NOT scan /proc/*/cmdline with tr: toybox tr on a dying PID's cmdline
# can hang forever and stall Format Data. Do NOT `stop` start_vibrator.sh
# first — that wrapper is `while true` and stop waits for a clean exit.
#

log() { echo "preformatdata: $*" > /dev/kmsg; }

log "releasing vendor mounts and userdata mapper for Format Data"

setprop sys.usb.ffs.mtp.ready 0 2>/dev/null
cur="$(getprop sys.usb.config)"
case "$cur" in
	*mtp*) setprop sys.usb.config adb 2>/dev/null ;;
esac

for name in \
	start_vibrator.sh \
	vendor.qti.hardware.vibrator.service \
	android.hardware.boot@1.2-service \
	android.hardware.boot@1.0-service
do
	pid="$(pidof "$name" 2>/dev/null || true)"
	[ -n "$pid" ] && kill -9 $pid 2>/dev/null && log "kill $name pid=$pid"
done
stop vendor.qti.vibrator 2>/dev/null
stop vibrator 2>/dev/null

umount -l /data/user/0 2>/dev/null || true
umount -l /sdcard 2>/dev/null || true
umount -l /data 2>/dev/null || true

if [ -e /dev/block/mapper/userdata ] && [ -x /system/bin/dmctl ]; then
	if dmctl delete userdata; then
		log "dmctl deleted userdata mapper"
	else
		log "dmctl delete userdata failed"
	fi
fi

# Lazy umount once. Do not loop: umount -l can leave the entry in
# /proc/mounts until the last ref drops, which looks like a hang.
umount -l /vendor 2>/dev/null && log "umount -l /vendor" || true

log "vibrator=$(getprop init.svc.vendor.qti.vibrator) boot-qti=$(getprop init.svc.vendor.boot-qti) mapper=$(ls /dev/block/mapper/userdata 2>/dev/null || echo none)"
grep ' /vendor' /proc/mounts > /dev/kmsg 2>/dev/null || log "no /vendor mounts"
exit 0
