#!/system/bin/sh
#
# Early ADSP bring-up + publish CPU temp for TWRP.
# TWRP only enables the header temp widget if TW_CUSTOM_CPU_TEMP_PATH
# exists at DataManager init; we seed /tmp/twrp_cpu_temp in init.rc and
# keep refreshing it here after sensors become readable.
#

MODULE_PATH=/vendor/lib/modules
TEMP_FILE=/tmp/twrp_cpu_temp

load() {
	[ -f "$MODULE_PATH/$1" ] || return 0
	insmod "$MODULE_PATH/$1" 2>/dev/null \
		|| insmod -f "$MODULE_PATH/$1" 2>/dev/null \
		|| true
}

wait_for() {
	_path=$1
	_max=${2:-50}
	_i=0
	while [ ! -e "$_path" ] && [ "$_i" -lt "$_max" ]; do
		sleep 0.1
		_i=$((_i + 1))
	done
	[ -e "$_path" ]
}

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

# Prefer QCOM CPU / *-usr zones; else first readable zone.
publish_temp() {
	_val=""
	for z in /sys/class/thermal/thermal_zone*; do
		[ -r "$z/temp" ] || continue
		_type=$(cat "$z/type" 2>/dev/null)
		case "$_type" in
			*cpu*|*CPU*|*Cpu*|*usr*|*USR*)
				_v=$(cat "$z/temp" 2>/dev/null) || continue
				case "$_v" in
					""|*[!0-9-]* ) continue ;;
				esac
				# Ignore clearly invalid / unset readings
				if [ "$_v" -gt 0 ] && [ "$_v" -lt 120000 ]; then
					_val=$_v
					break
				fi
				;;
		esac
	done

	if [ -z "$_val" ]; then
		for z in /sys/class/thermal/thermal_zone*; do
			[ -r "$z/temp" ] || continue
			_v=$(cat "$z/temp" 2>/dev/null) || continue
			case "$_v" in
				""|*[!0-9-]* ) continue ;;
			esac
			if [ "$_v" -gt 0 ] && [ "$_v" -lt 120000 ]; then
				_val=$_v
				break
			fi
		done
	fi

	[ -n "$_val" ] || return 1
	echo "$_val" > "$TEMP_FILE"
	return 0
}

# Seed (init.rc should already create this; keep robust)
mkdir -p /tmp
[ -f "$TEMP_FILE" ] || echo 0 > "$TEMP_FILE"

# ADSP stack so QMI/tsens-backed zones can report
load q6_pdr_dlkm.ko
load q6_notifier_dlkm.ko
load snd_event_dlkm.ko
load apr_dlkm.ko
load adsp_loader_dlkm.ko
mount_vendor_ro

if wait_for /sys/kernel/boot_adsp/boot 80; then
	echo 1 > /sys/kernel/boot_adsp/boot
fi

# Refresh for a while, then slow loop (recovery is long-lived)
_i=0
while [ "$_i" -lt 30 ]; do
	publish_temp && break
	sleep 0.5
	_i=$((_i + 1))
done

while true; do
	publish_temp || true
	sleep 5
done
