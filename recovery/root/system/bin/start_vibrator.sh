#!/system/bin/sh
# System libbinder* MUST come before /vendor/lib64 — otherwise AIDL vibrator
# mixes SYST/VNDR binder parcels and aborts ("Mixing copies of libbinder").
export LD_LIBRARY_PATH=/system/lib64:/system/lib:/vendor/lib64:/vendor/lib:/sbin

# Wait briefly for servicemanager; retry a couple times if HAL exits early.
i=0
while [ "$i" -lt 30 ]; do
	[ "$(getprop init.svc.servicemanager)" = "running" ] && break
	i=$((i + 1))
	sleep 0.1
done

BIN=/system/bin/vendor.qti.hardware.vibrator.service
[ -x "$BIN" ] || BIN=/vendor/bin/hw/vendor.qti.hardware.vibrator.service
if [ ! -x "$BIN" ]; then
	echo "start_vibrator: binary missing" > /dev/kmsg
	exit 1
fi

# After Format Data, super /vendor is unmapped. If the mapper is back, remount
# so vibratorOL/Sel can resolve the rest of the vendor lib chain.
slot="$(getprop ro.boot.slot_suffix)"
if [ -n "$slot" ] && [ -e "/dev/block/mapper/vendor${slot}" ]; then
	if ! grep -q ' /vendor ' /proc/mounts 2>/dev/null; then
		if mount -t erofs -o ro "/dev/block/mapper/vendor${slot}" /vendor \
			|| mount -t ext4 -o ro "/dev/block/mapper/vendor${slot}" /vendor; then
			echo "start_vibrator: mounted vendor${slot}" > /dev/kmsg
		else
			echo "start_vibrator: mount vendor${slot} failed" > /dev/kmsg
		fi
	fi
fi

# Keep HAL alive for the recovery session. First start often races
# servicemanager (exit=1); later Format Data may SIGKILL this wrapper.
tries=0
while true; do
	"$BIN"
	rc=$?
	tries=$((tries + 1))
	echo "start_vibrator: exit=$rc try=$tries" > /dev/kmsg
	sleep 1
done
