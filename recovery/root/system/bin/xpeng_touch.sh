#!/system/bin/sh

module_path=/sbin/modules
firmware_path=/sbin/firmware
touch_class_path=/sys/class/touchscreen

# Preferred order for 5.4.302 touch stack; -f: kernel vermagic string may differ
insmod -f $module_path/mmi_annotate.ko
insmod -f $module_path/mmi_relay.ko
insmod -f $module_path/sensors_class.ko
insmod -f $module_path/touchscreen_mmi.ko
insmod -f $module_path/nova_0flash_mmi.ko

# Optional firmware force-reflash (nova sysfs); ignore failures
if [ -d "$touch_class_path" ]; then
  cd $firmware_path 2>/dev/null || cd /vendor/firmware
  touch_product_string=$(ls $touch_class_path 2>/dev/null | head -n1)
  firmware_file="novatek_ts-NT36675-21101302-6044-xpeng.bin"
  if [ -n "$touch_product_string" ] && [ -f "$touch_class_path/$touch_product_string/path" ]; then
    touch_path=/sys$(cat $touch_class_path/$touch_product_string/path | awk '{print $1}')
    if [ -n "$touch_path" ] && [ -d "$touch_path" ]; then
      echo $firmware_file > $touch_path/doreflash 2>/dev/null
      echo 1 > $touch_path/forcereflash 2>/dev/null
      sleep 2
      echo 1 > $touch_path/reset 2>/dev/null
    fi
  fi
fi

exit 0
