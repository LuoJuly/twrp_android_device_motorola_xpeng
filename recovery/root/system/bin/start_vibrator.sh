#!/system/bin/sh
# Run vibrator HAL outside init's crash-restart loop.
# If addService fails (VINTF/etc), abort once — do not hammer UI every 5s.
exec /system/bin/vendor.qti.hardware.vibrator.service
