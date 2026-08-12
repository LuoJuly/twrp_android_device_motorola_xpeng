#!/system/bin/sh
# If Mount→MTP leaves sys.usb.config=mtp,adb but userspace never sets
# sys.usb.ffs.mtp.ready (or MTP FFS dies with errno 108), UDC stays unbound /
# composite breaks and host ADB disappears until cable replug.
# Always fall back to plain adb.

restore_adb() {
	echo "mtp_usb_guard: $1 — restoring adb" > /dev/kmsg
	setprop sys.usb.ffs.mtp.ready 0
	setprop sys.usb.config none
	sleep 0.3
	setprop sys.usb.config adb
	# One more nudge if dwc3 did not rebind
	i=0
	while [ "$i" -lt 20 ]; do
		if [ "$(getprop sys.usb.state)" = "adb" ] && [ "$(getprop init.svc.adbd)" = "running" ]; then
			echo "mtp_usb_guard: adb restored" > /dev/kmsg
			return 0
		fi
		i=$((i + 1))
		sleep 0.2
	done
	# Soft re-toggle once
	setprop sys.usb.config none
	sleep 0.3
	setprop sys.usb.config adb
	echo "mtp_usb_guard: adb restore attempted (state=$(getprop sys.usb.state))" > /dev/kmsg
}

# First check after a short settle (ffs.mtp.ready should appear quickly)
sleep 2
cfg="$(getprop sys.usb.config)"
ready="$(getprop sys.usb.ffs.mtp.ready)"
if [ "$cfg" = "mtp,adb" ] && [ "$ready" != "1" ]; then
	restore_adb "mtp.ready missing"
	exit 0
fi

# Second check: MTP claimed ready but gadget/ADB may still be dead after
# bulk-in failures (errno 108 / ESHUTDOWN on this dwc3).
sleep 3
cfg="$(getprop sys.usb.config)"
if [ "$cfg" = "mtp,adb" ]; then
	udc="$(cat /config/usb_gadget/g1/UDC 2>/dev/null)"
	adb_ok=0
	[ "$(getprop init.svc.adbd)" = "running" ] && [ -n "$udc" ] && [ "$udc" != "none" ] && adb_ok=1
	if [ "$adb_ok" != "1" ]; then
		restore_adb "mtp,adb but adbd/UDC unhealthy (udc=$udc)"
	fi
fi
exit 0
