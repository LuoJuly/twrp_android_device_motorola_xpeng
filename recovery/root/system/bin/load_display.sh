#!/system/bin/sh
#
# Load display stack as early as possible (before TWRP GUI).
# msm_drm is modular on lahaina; without it recovery has no /dev/dri → black screen.
# msm_drm.ko stays on vendor_boot (/lib/modules, ~3.9MiB); other kos ship in
# boot ramdisk under /vendor/lib/modules.
#
# Do not wait/loop here: this script is exec'd from on early-boot and blocks
# init (no recovery GUI, no enable_adb) until it returns.
#

load() {
	for MOD in /vendor/lib/modules /lib/modules /sbin/modules; do
		[ -f "$MOD/$1" ] || continue
		insmod "$MOD/$1" 2>/dev/null || insmod -f "$MOD/$1" 2>/dev/null || true
		return 0
	done
	return 0
}

load mmi_annotate.ko
load mmi_info.ko
load mmi_relay.ko
load sensors_class.ko
load msm_drm.ko
load touchscreen_mmi.ko
load nova_0flash_mmi.ko

exit 0
