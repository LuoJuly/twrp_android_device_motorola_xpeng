#!/system/bin/sh
# Enable default ADB using the same USB sequence as Lineage recovery UI /
# TWRP GUIAction::enableadb: sys.usb.config none -> adb
# Requires configfs gadget from stock init.rc (fs && sys.usb.configfs=1).
#
# Idempotent: if ADB is already live, do NOT toggle none→adb. A soft
# reconnect on this dwc3 frequently fails to re-enumerate until replug.

log() {
	echo "enable_adb: $*" > /dev/kmsg 2>/dev/null || true
}

adb_healthy() {
	ctrl="$(getprop sys.usb.controller)"
	udc="$(cat /config/usb_gadget/g1/UDC 2>/dev/null)"
	[ "$(getprop sys.usb.state)" = "adb" ] || return 1
	[ "$(getprop sys.usb.ffs.ready)" = "1" ] || return 1
	[ "$(getprop init.svc.adbd)" = "running" ] || return 1
	[ -n "$ctrl" ] && [ "$udc" = "$ctrl" ] || return 1
	return 0
}

if adb_healthy; then
	log "already healthy state=adb udc=$(cat /config/usb_gadget/g1/UDC 2>/dev/null) — skip toggle"
	exit 0
fi

# Wait for Lineage-style stock gadget + functionfs (created on fs)
i=0
while [ "$i" -lt 50 ]; do
	ctrl="$(getprop sys.usb.controller)"
	if [ -z "$ctrl" ]; then
		ctrl="$(getprop ro.boot.usbcontroller)"
		[ -n "$ctrl" ] && setprop sys.usb.controller "$ctrl"
	fi
	if [ -z "$ctrl" ] || [ ! -d "/sys/class/udc/$ctrl" ]; then
		for d in /sys/class/udc/*; do
			[ -e "$d" ] || continue
			ctrl="$(basename "$d")"
			setprop sys.usb.controller "$ctrl"
			break
		done
	fi
	if [ -n "$ctrl" ] && [ -d "/sys/class/udc/$ctrl" ] \
		&& [ -d /dev/usb-ffs/adb ] \
		&& [ -d /config/usb_gadget/g1/functions/ffs.adb ]; then
		break
	fi
	i=$((i + 1))
	sleep 0.2
done

ctrl="$(getprop sys.usb.controller)"
log "configfs=$(getprop sys.usb.configfs) ctrl=$ctrl ffs_adb=$([ -d /dev/usb-ffs/adb ] && echo y || echo n) g1=$([ -d /config/usb_gadget/g1/functions/ffs.adb ] && echo y || echo n)"

if [ "$(getprop sys.usb.configfs)" != "1" ]; then
	setprop sys.usb.configfs 1
fi

if [ -z "$ctrl" ] || [ ! -d "/sys/class/udc/$ctrl" ]; then
	log "no UDC; abort"
	exit 1
fi
if [ ! -d /dev/usb-ffs/adb ] || [ ! -d /config/usb_gadget/g1/functions/ffs.adb ]; then
	log "gadget/ffs not ready; abort"
	exit 1
fi

# Dual-role so OTG host still works after ADB bring-up (not forced peripheral).
# Only write when needed — rewriting mode triggers a Cable disconnected storm.
mode_path="/sys/class/udc/$ctrl/device/../mode"
if [ -e "$mode_path" ]; then
	cur_mode="$(cat "$mode_path" 2>/dev/null)"
	if [ "$cur_mode" != "otg" ]; then
		echo otg > "$mode_path" 2>/dev/null || true
		log "mode $cur_mode -> otg"
	fi
fi

setprop sys.usb.config none
sleep 0.5
setprop sys.usb.config adb

i=0
while [ "$i" -lt 30 ]; do
	if [ "$(getprop sys.usb.state)" = "adb" ]; then
		log "ok state=adb svc=$(getprop init.svc.adbd) ffs=$(getprop sys.usb.ffs.ready) udc=$(cat /config/usb_gadget/g1/UDC 2>/dev/null)"
		exit 0
	fi
	i=$((i + 1))
	sleep 0.2
done

log "retry toggle (state=$(getprop sys.usb.state) ffs=$(getprop sys.usb.ffs.ready) svc=$(getprop init.svc.adbd))"
setprop sys.usb.config none
sleep 0.5
setprop sys.usb.config adb
sleep 1
log "done state=$(getprop sys.usb.state) ffs=$(getprop sys.usb.ffs.ready) svc=$(getprop init.svc.adbd) udc=$(cat /config/usb_gadget/g1/UDC 2>/dev/null)"
exit 0
