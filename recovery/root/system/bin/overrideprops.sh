#!/system/bin/sh

resetprop ro.build.date.utc 0000000000
resetprop ro.system.build.date.utc 0000000000
resetprop ro.system_ext.build.date.utc 0000000000
resetprop ro.vendor.build.date.utc 0000000000
resetprop ro.odm.build.date.utc 0000000000
resetprop ro.product.build.date.utc 0000000000

# Ensure update_engine sees VAB even if prop.default was stale.
resetprop ro.virtual_ab.enabled true

exit 0
