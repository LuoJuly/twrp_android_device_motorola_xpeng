#!/system/bin/sh
#
# Run before Format Data / dynamic-partition unmap.
# Vibrator (and any leftover vendor HAL) can keep /vendor busy so
# DestroyLogicalPartition(vendor_b) fails. AIDL boot HAL does not mmap
# /vendor/lib64/hw — do not kill vendor.boot-qti (update_engine needs it).
#
# Also release /data and the dm-default-key userdata mapper so make_f2fs
# can exclusive-open the raw userdata partition (sde25).
#

log() { echo "preformatdata: $*" > /dev/kmsg; }

log "releasing vendor mounts and userdata mapper for Format Data"

# Prefer adb-only so MTP does not keep /data busy.
setprop sys.usb.ffs.mtp.ready 0 2>/dev/null
cur="$(getprop sys.usb.config)"
case "$cur" in
	*mtp*) setprop sys.usb.config adb 2>/dev/null ;;
esac

stop vendor.qti.vibrator 2>/dev/null
stop vibrator 2>/dev/null

for name in \
	vendor.qti.hardware.vibrator.service \
	start_vibrator.sh \
	android.hardware.boot@1.2-service \
	android.hardware.boot@1.0-service
do
	pid="$(pidof "$name" 2>/dev/null || true)"
	[ -n "$pid" ] && kill -9 $pid 2>/dev/null && log "kill $name pid=$pid"
done

for p in /proc/[0-9]*; do
	[ -r "$p/cmdline" ] || continue
	cmd="$(tr '\0' ' ' < "$p/cmdline" 2>/dev/null || true)"
	case "$cmd" in
		*qti.hardware.vibrator*|*hardware.boot@*)
			kill -9 "$(basename "$p")" 2>/dev/null
			log "killed $(basename "$p"): $cmd"
			;;
	esac
done

# Drop /data so dmctl / DeviceMapper can remove the userdata mapping.
umount -l /data/user/0 2>/dev/null || true
umount -l /data 2>/dev/null || true
sleep 0.3

if [ -e /dev/block/mapper/userdata ]; then
	if [ -x /system/bin/dmctl ]; then
		if dmctl delete userdata; then
			log "dmctl deleted userdata mapper"
		else
			log "dmctl delete userdata failed"
		fi
	else
		log "userdata mapper still present (recovery will delete it)"
	fi
fi

sleep 0.2

while grep -q ' /vendor' /proc/mounts 2>/dev/null; do
	mp="$(awk '$2 ~ /^\/vendor(\/|$)/ {print $2}' /proc/mounts | sort -r | head -1)"
	[ -n "$mp" ] || break
	if umount -l "$mp" 2>/dev/null; then
		log "umount -l $mp"
	else
		log "umount fail $mp"
		break
	fi
done

log "vibrator=$(getprop init.svc.vendor.qti.vibrator) boot-qti=$(getprop init.svc.vendor.boot-qti) mapper=$(ls /dev/block/mapper/userdata 2>/dev/null || echo none)"
grep ' /vendor' /proc/mounts > /dev/kmsg 2>/dev/null || log "no /vendor mounts"
exit 0
