#!/system/bin/sh
# If Mount→MTP / auto-MTP leaves sys.usb.config=mtp,adb but userspace never
# sets sys.usb.ffs.mtp.ready, UDC stays unbound and ADB dies. Fall back to adb.

sleep 3

cfg="$(getprop sys.usb.config)"
ready="$(getprop sys.usb.ffs.mtp.ready)"

if [ "$cfg" = "mtp,adb" ] && [ "$ready" != "1" ]; then
	echo "mtp_usb_guard: mtp.ready missing — restoring adb" > /dev/kmsg
	setprop sys.usb.config none
	sleep 0.2
	setprop sys.usb.config adb
fi
