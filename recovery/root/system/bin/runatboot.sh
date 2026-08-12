#!/system/bin/sh

# Run TouchScreen Patch For Stock Users
# Modules come from vendor_boot (/lib/modules); only firmware is in boot ramdisk.

path=/sbin
if [ -d /lib/modules ]; then
	ln -sfn /lib/modules "$path/modules" 2>/dev/null || cp -r /lib/modules "$path/modules"
elif [ -d /vendor/lib/modules ]; then
	cp -r /vendor/lib/modules "$path/modules"
fi
cp -r /vendor/firmware "$path/firmware" 2>/dev/null || true
/system/bin/sh /system/bin/xpeng_touch.sh 2> "$path/TouchScreenlog.txt"
/system/bin/sh /system/bin/xpeng_touch.sh 2>> "$path/TouchScreenlog.txt"

exit 0
