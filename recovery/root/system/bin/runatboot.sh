#!/system/bin/sh

# Run TouchScreen Patch For Stock Users

path=/sbin
cp -r /vendor/lib/modules $path
cp -r /vendor/firmware $path
/system/bin/sh /system/bin/xpeng_touch.sh 2> $path/TouchScreenlog.txt
/system/bin/sh /system/bin/xpeng_touch.sh 2>> $path/TouchScreenlog.txt

exit 0
