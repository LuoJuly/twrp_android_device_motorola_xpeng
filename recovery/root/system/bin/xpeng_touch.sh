#!/system/bin/sh
#
# Load recovery modules + boot ADSP so battery SOC works (LineageOS
# modules.load.recovery: bm_adsp_ulog / charger / adsp_loader stack).
#

module_path=/sbin/modules
firmware_path=/sbin/firmware
touch_class_path=/sys/class/touchscreen

load() {
	# Prefer normal insmod; -f as fallback for vermagic skew
	insmod "$module_path/$1" 2>/dev/null \
		|| insmod -f "$module_path/$1" 2>/dev/null \
		|| true
}

wait_for() {
	# wait_for <path> [tenths of a second]
	_path=$1
	_max=${2:-50}
	_i=0
	while [ ! -e "$_path" ] && [ "$_i" -lt "$_max" ]; do
		sleep 0.1
		_i=$((_i + 1))
	done
	[ -e "$_path" ]
}

# --- misc fs ---
load exfat.ko

# ADSP + battery are handled by init_thermal.sh (Lineage: modem→/firmware).
# Minimal mmi stack for touch (audio/fp/sar modules removed to shrink ramdisk).
load mmi_info.ko
load mmi_annotate.ko
load mmi_relay.ko
load qpnp_adaptive_charge.ko
load mmi_sys_temp.ko
load sensors_class.ko
load utags.ko

# --- touch (needs msm_drm stub for panel notifier) ---
load msm_drm.ko
load touchscreen_mmi.ko
load nova_0flash_mmi.ko

# Never set sys.usb.config to anything other than adb/fastboot/none.
# (Previously "true" overwrote adb and left ADB dead after touch init.)

cd "$firmware_path" || exit 0
touch_product_string=$(ls "$touch_class_path" 2>/dev/null)
echo "novatek"
firmware_file="novatek_ts-NT36675-21101302-6044-xpeng.bin"
if [ -n "$touch_product_string" ] && [ -e "$touch_class_path/$touch_product_string/path" ]; then
	touch_path=/sys$(cat "$touch_class_path/$touch_product_string/path" | awk '{print $1}')
	echo "$firmware_file" > "$touch_path/doreflash"
	echo 1 > "$touch_path/forcereflash"
	sleep 5
	echo 1 > "$touch_path/reset"
fi
