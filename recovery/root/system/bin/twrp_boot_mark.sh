#!/system/bin/sh
mkdir -p /cache/recovery 2>/dev/null
echo "TWRP_MARK $(cat /proc/uptime 2>/dev/null)" > /cache/recovery/twrp_boot_mark.txt 2>/dev/null
echo "TWRP_MARK" > /dev/kmsg 2>/dev/null
ls -la /dev/dri > /cache/recovery/twrp_dri.txt 2>/dev/null
exit 0
