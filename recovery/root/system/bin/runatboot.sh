#!/system/bin/sh

# Run TouchScreen Patch For Stock Users

path=/sbin
cp -r /vendor/lib/modules $path
cp -r /vendor/firmware $path
# Also expose firmware where request_firmware commonly looks
mkdir -p /lib/firmware /vendor/firmware
cp -f /sbin/firmware/* /lib/firmware/ 2>/dev/null
cp -f /sbin/firmware/* /vendor/firmware/ 2>/dev/null

/system/bin/sh /system/bin/xpeng_touch.sh 2> $path/TouchScreenlog.txt
/system/bin/sh /system/bin/xpeng_touch.sh 2>> $path/TouchScreenlog.txt

exit 0
