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

# Keep HAL alive for the recovery session (oneshot wrapper would leave
# init.svc=stopped after a single crash and kill haptics).
tries=0
while [ "$tries" -lt 5 ]; do
	"$BIN"
	rc=$?
	tries=$((tries + 1))
	echo "start_vibrator: exit=$rc try=$tries" > /dev/kmsg
	sleep 1
done
exit 0
