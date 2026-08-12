#!/system/bin/sh
#
# Load display stack as early as possible (before TWRP GUI).
# msm_drm is modular on lahaina; without it recovery has no /dev/dri → black screen.
# Prefer vendor_boot /lib/modules (not duplicated into boot ramdisk).
#

for MOD in /lib/modules /vendor/lib/modules /sbin/modules; do
	[ -d "$MOD" ] && break
done

load() {
	[ -f "$MOD/$1" ] || return 0
	insmod "$MOD/$1" 2>/dev/null || insmod -f "$MOD/$1" 2>/dev/null || true
}

load mmi_annotate.ko
load mmi_info.ko
load mmi_relay.ko
load sensors_class.ko
load msm_drm.ko
load touchscreen_mmi.ko
load nova_0flash_mmi.ko

exit 0
