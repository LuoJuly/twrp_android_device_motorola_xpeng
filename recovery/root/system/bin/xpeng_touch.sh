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

# Mount vendor (ro) so PIL can load ADSP firmware for PMIC/glink battery
mount_vendor_ro() {
	[ -d /vendor/firmware ] && return 0
	[ -d /vendor/firmware_mnt ] && return 0
	slot=$(getprop ro.boot.slot_suffix)
	mkdir -p /vendor
	for node in \
		"/dev/block/bootdevice/by-name/vendor${slot}" \
		"/dev/block/by-name/vendor${slot}"
	do
		if [ -e "$node" ]; then
			mount -t ext4 -o ro "$node" /vendor 2>/dev/null && return 0
		fi
	done
	return 0
}

# --- misc fs ---
load exfat.ko

# --- ADSP stack (deps: q6_pdr -> q6_notifier -> snd_event -> apr -> adsp_loader) ---
load q6_pdr_dlkm.ko
load q6_notifier_dlkm.ko
load snd_event_dlkm.ko
load apr_dlkm.ko
load adsp_loader_dlkm.ko

# --- Motorola charger / battery (LOS modules.load.recovery) ---
# qti_battery_charger is built-in (CONFIG_QTI_BATTERY_CHARGER=y) and exposes
# /sys/class/power_supply/battery once ADSP/glink is alive.
load mmi_info.ko
load mmi_annotate.ko
load bm_adsp_ulog.ko
load mmi_charger.ko
load qti_glink_charger.ko
load qpnp_adaptive_charge.ko

mount_vendor_ro

# Boot ADSP (was incorrectly using init.rc "wait"/"write" in this shell)
if wait_for /sys/kernel/boot_adsp/boot 80; then
	echo 1 > /sys/kernel/boot_adsp/boot
	# Allow glink + battery profile to come up
	_i=0
	while [ "$_i" -lt 50 ]; do
		if [ -r /sys/class/power_supply/battery/capacity ]; then
			cap=$(cat /sys/class/power_supply/battery/capacity 2>/dev/null)
			# Ignore empty / placeholder until a numeric value appears
			case "$cap" in
				"" ) ;;
				*[!0-9]* ) ;;
				*) break ;;
			esac
		fi
		sleep 0.2
		_i=$((_i + 1))
	done
fi

# --- other mmi / sensors ---
load moto_f_usbnet.ko
load sx937x_sar.ko
load fpc1020_mmi.ko
load mmi_sys_temp.ko
load mmi_relay.ko
load sensors_class.ko
load utags.ko
load aw882xx_k504.ko

# --- touch (needs msm_drm stub for panel notifier) ---
load msm_drm.ko
load touchscreen_mmi.ko
load nova_0flash_mmi.ko

setprop sys.usb.config true

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
