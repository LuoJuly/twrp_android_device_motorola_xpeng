#!/system/bin/sh
#
# LineageOS-style ADSP bring-up + publish CPU temp / battery for TWRP UI.
#
# Lineage init.qcom.recovery.rc:
#   mount modem -> /firmware, then write /sys/kernel/boot_adsp/boot 1,
#   wait /sys/class/power_supply/battery
# Health HAL then reads /sys/class/power_supply/battery/capacity.
#
# We mirror the firmware/ADSP path and publish capacity for TWRP legacy UI:
#   TW_CUSTOM_CPU_TEMP_PATH=/tmp/twrp_cpu_temp
#   TW_CUSTOM_BATTERY_PATH=/tmp/twrp_battery
#

# Single instance (may be started from firmware-mount + on boot)
if [ -f /tmp/init_thermal.lock ]; then
	exit 0
fi
echo $$ > /tmp/init_thermal.lock

MODULE_PATH=/vendor/lib/modules
[ -d "$MODULE_PATH" ] || MODULE_PATH=/lib/modules
[ -d "$MODULE_PATH" ] || MODULE_PATH=/sbin/modules
TEMP_FILE=/tmp/twrp_cpu_temp
BATT_DIR=/tmp/twrp_battery
BATT_CAP=$BATT_DIR/capacity
BATT_STAT=$BATT_DIR/status

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

# Lineage: ADSP PIL firmware is on the modem partition at /firmware
ensure_modem_firmware() {
	# Already mounted by init.recovery.qcom.rc?
	if mountpoint -q /firmware 2>/dev/null || grep -q ' /firmware ' /proc/mounts 2>/dev/null; then
		return 0
	fi
	slot=$(getprop ro.boot.slot_suffix)
	mkdir -p /firmware
	for node in \
		"/dev/block/bootdevice/by-name/modem${slot}" \
		"/dev/block/by-name/modem${slot}"
	do
		if [ -e "$node" ]; then
			mount -t ext4 -o ro "$node" /firmware 2>/dev/null && return 0
		fi
	done
	return 1
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

# Clamp to 1..100 (theme hides 0 and >=101).
clamp_pct() {
	_c=$1
	case "$_c" in
		""|*[!0-9-]* ) return 1 ;;
	esac
	if [ "$_c" -le 0 ]; then
		_c=1
	elif [ "$_c" -gt 100 ]; then
		_c=100
	fi
	echo "$_c"
}

# Normalize capacity sysfs (percent / tenths / millipercent) to 1..100.
normalize_cap() {
	_c=$1
	case "$_c" in
		""|*[!0-9]* ) return 1 ;;
	esac
	if [ "$_c" -gt 1000 ]; then
		_c=$((_c / 100))
	elif [ "$_c" -gt 100 ]; then
		_c=$((_c / 10))
	fi
	clamp_pct "$_c"
}

read_int_file() {
	_f=$1
	[ -r "$_f" ] || return 1
	_raw=$(cat "$_f" 2>/dev/null) || return 1
	case "$_raw" in
		""|*[!0-9-]* ) return 1 ;;
	esac
	echo "$_raw"
}

# Rough Li-ion SOC from voltage_now (uV). Used when FG reports placeholder 100/0.
soc_from_voltage() {
	_uv=$1
	case "$_uv" in
		""|*[!0-9-]* ) return 1 ;;
	esac
	# Ignore implausible readings
	if [ "$_uv" -lt 2500000 ] || [ "$_uv" -gt 5000000 ]; then
		return 1
	fi
	if [ "$_uv" -le 3400000 ]; then
		echo 1
		return 0
	fi
	if [ "$_uv" -ge 4200000 ]; then
		echo 100
		return 0
	fi
	# Linear 3.40V..4.20V -> 0..100
	clamp_pct $(( (_uv - 3400000) * 100 / 800000 ))
}

soc_from_charge_counter() {
	_dir=$1
	_cc=$(read_int_file "$_dir/charge_counter") || return 1
	_cf=$(read_int_file "$_dir/charge_full") || return 1
	if [ "$_cf" -le 1000 ] || [ "$_cc" -lt 0 ]; then
		return 1
	fi
	clamp_pct $(( _cc * 100 / _cf ))
}

# Pick best SOC: reject FG placeholder 100/0 when voltage/coulomb disagree.
best_soc_from_dir() {
	_dir=$1
	[ -d "$_dir" ] || return 1

	_cap=""
	if [ -r "$_dir/capacity" ]; then
		_cap=$(normalize_cap "$(cat "$_dir/capacity" 2>/dev/null)") || _cap=""
	fi
	_soc_cc=$(soc_from_charge_counter "$_dir") || _soc_cc=""
	_uv=$(read_int_file "$_dir/voltage_now") || _uv=""
	_soc_v=""
	[ -n "$_uv" ] && _soc_v=$(soc_from_voltage "$_uv") || _soc_v=""

	# Coulomb counter is usually best once ADSP/glink is up
	if [ -n "$_soc_cc" ]; then
		if [ -z "$_cap" ] || [ "$_cap" = "100" ] || [ "$_cap" = "1" ]; then
			echo "$_soc_cc"
			return 0
		fi
		_diff=$((_cap - _soc_cc))
		[ "$_diff" -lt 0 ] && _diff=$((- _diff))
		if [ "$_diff" -ge 8 ]; then
			echo "$_soc_cc"
			return 0
		fi
		echo "$_cap"
		return 0
	fi

	# Placeholder 100%/0% with mid voltage -> trust voltage curve
	if [ -n "$_soc_v" ]; then
		if [ "$_cap" = "100" ] && [ "$_soc_v" -lt 95 ]; then
			echo "$_soc_v"
			return 0
		fi
		if [ "$_cap" = "1" ] && [ "$_soc_v" -gt 5 ]; then
			echo "$_soc_v"
			return 0
		fi
		if [ -z "$_cap" ]; then
			echo "$_soc_v"
			return 0
		fi
	fi

	[ -n "$_cap" ] || return 1
	echo "$_cap"
}

publish_battery() {
	_cap=""
	# main_battery: Moto qti_glink OEM batt_info (often more accurate once up)
	# battery: built-in qti_battery_charger
	for _d in \
		/sys/class/power_supply/main_battery \
		/sys/class/power_supply/battery \
		/sys/class/power_supply/bms \
		/sys/class/power_supply/mmi_battery
	do
		_cap=$(best_soc_from_dir "$_d") && break
		_cap=""
	done

	if [ -z "$_cap" ]; then
		for _d in /sys/class/power_supply/*; do
			[ -r "$_d/capacity" ] || [ -r "$_d/voltage_now" ] || continue
			_cap=$(best_soc_from_dir "$_d") && break
			_cap=""
		done
	fi

	[ -n "$_cap" ] || return 1
	echo "$_cap" > "$BATT_CAP"

	_st="Discharging"
	for _f in \
		/sys/class/power_supply/main_battery/status \
		/sys/class/power_supply/battery/status \
		/sys/class/power_supply/mmi_battery/status
	do
		if [ -r "$_f" ]; then
			_st=$(cat "$_f" 2>/dev/null)
			[ -n "$_st" ] && break
		fi
	done
	echo "$_st" > "$BATT_STAT"
	return 0
}

# True when reading looks like a real FG value (not the common 100% stub).
battery_trusted() {
	_c=$(cat "$BATT_CAP" 2>/dev/null) || return 1
	case "$_c" in
		""|*[!0-9]* ) return 1 ;;
	esac
	# Prefer anything other than the common unset stub
	[ "$_c" != "100" ] && [ "$_c" != "50" ] && return 0
	# 100 is ok only if voltage says nearly full
	for _d in \
		/sys/class/power_supply/main_battery \
		/sys/class/power_supply/battery
	do
		_uv=$(read_int_file "$_d/voltage_now") || continue
		[ "$_uv" -ge 4100000 ] && return 0
	done
	return 1
}

mkdir -p /tmp "$BATT_DIR"
[ -f "$TEMP_FILE" ] || echo 0 > "$TEMP_FILE"
# Seed in-range value so header battery is not hidden as "-1%"
[ -f "$BATT_CAP" ] || echo 1 > "$BATT_CAP"
[ -f "$BATT_STAT" ] || echo Discharging > "$BATT_STAT"

# Modem firmware must be present before booting ADSP (Lineage path)
ensure_modem_firmware
# Wait a bit for init.rc mount if we raced ahead of on fs
_i=0
while [ "$_i" -lt 50 ]; do
	grep -q ' /firmware ' /proc/mounts 2>/dev/null && break
	ensure_modem_firmware && break
	sleep 0.1
	_i=$((_i + 1))
done

# ADSP stack (battery SOC via pmic glink needs ADSP)
load q6_pdr_dlkm.ko
load q6_notifier_dlkm.ko
load snd_event_dlkm.ko
load apr_dlkm.ko
load adsp_loader_dlkm.ko
# Moto charger helpers (optional; built-in qti_battery_charger is primary)
load mmi_info.ko
load bm_adsp_ulog.ko
load mmi_charger.ko
load qti_glink_charger.ko

# Lineage: write /sys/kernel/boot_adsp/boot 1 ; wait battery
if wait_for /sys/kernel/boot_adsp/boot 80; then
	echo 1 > /sys/kernel/boot_adsp/boot
fi
wait_for /sys/class/power_supply/battery 100 || true
# Extra settle for capacity after psy appears
_i=0
while [ "$_i" -lt 40 ]; do
	if [ -r /sys/class/power_supply/battery/capacity ]; then
		_c=$(cat /sys/class/power_supply/battery/capacity 2>/dev/null)
		case "$_c" in
			""|*[!0-9]* ) ;;
			*) break ;;
		esac
	fi
	sleep 0.25
	_i=$((_i + 1))
done

# Wait for a trusted SOC (do not stop on the first placeholder 100%)
_i=0
while [ "$_i" -lt 60 ]; do
	publish_temp || true
	publish_battery || true
	battery_trusted && break
	sleep 0.5
	_i=$((_i + 1))
done

while true; do
	publish_temp || true
	publish_battery || true
	sleep 2
done
