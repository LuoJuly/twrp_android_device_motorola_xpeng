#!/system/bin/sh

# Run TouchScreen Patch For Stock Users
# Modules come from vendor_boot (/lib/modules); touch FW is in boot ramdisk
# at /lib/firmware (not mounted /vendor — that overlay is hidden/corrupt after
# Format Data / sideload).

path=/sbin
if [ -d /lib/modules ]; then
	ln -sfn /lib/modules "$path/modules" 2>/dev/null || cp -r /lib/modules "$path/modules"
elif [ -d /vendor/lib/modules ]; then
	cp -r /vendor/lib/modules "$path/modules"
fi

mkdir -p "$path/firmware" /lib/firmware
fw_name="novatek_ts-NT36675-21101302-6044-xpeng.bin"
fw_src=""
for d in /lib/firmware /system/etc/firmware; do
	if [ -f "$d/$fw_name" ]; then
		fw_src="$d/$fw_name"
		break
	fi
done
# Readable ramdisk /vendor copy only (ignore EUCLEAN on mounted super vendor).
if [ -z "$fw_src" ] && [ -f /vendor/firmware/$fw_name ]; then
	if cat /vendor/firmware/$fw_name >/dev/null 2>&1; then
		fw_src=/vendor/firmware/$fw_name
	fi
fi
if [ -n "$fw_src" ]; then
	cp -f "$fw_src" "$path/firmware/$fw_name" 2>/dev/null || true
	cp -f "$fw_src" "/lib/firmware/$fw_name" 2>/dev/null || true
	# Driver resume name (panel-supplier tm).
	cp -f "$fw_src" "$path/firmware/tm_novatek_ts_fw.bin" 2>/dev/null || true
	cp -f "$fw_src" "/lib/firmware/tm_novatek_ts_fw.bin" 2>/dev/null || true
fi

/system/bin/sh /system/bin/xpeng_touch.sh 2> "$path/TouchScreenlog.txt"
/system/bin/sh /system/bin/xpeng_touch.sh 2>> "$path/TouchScreenlog.txt"

exit 0
