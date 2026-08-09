#!/system/bin/sh

module_path=/sbin/modules
firmware_path=/sbin/firmware
touch_class_path=/sys/class/touchscreen
insmod $module_path/exfat.ko
insmod $module_path/adsp_loader_dlkm.ko
insmod $module_path/aw882xx_k504.ko
insmod $module_path/mmi_info.ko
insmod $module_path/mmi_relay.ko
insmod $module_path/moto_f_usbnet.ko
insmod $module_path/qpnp_adaptive_charge.ko
insmod $module_path/qti_battery_charger_main.ko
insmod $module_path/qti_glink_charger.ko
insmod $module_path/sx937x_sar.ko
insmod $module_path/fpc1020_mmi.ko
insmod $module_path/mmi_annotate.ko
insmod $module_path/mmi_charger.ko
insmod $module_path/mmi_sys_temp.ko
insmod $module_path/sensors_class.ko
insmod $module_path/utags.ko
insmod $module_path/nova_0flash_mmi.ko
insmod $module_path/touchscreen_mmi.ko
setprop sys.usb.config true
    # Load ADSP firmware for PMIC
    wait /sys/kernel/boot_adsp/boot
    write /sys/kernel/boot_adsp/boot 1
    wait /sys/class/power_supply/mmi_battery
    start health-hal-2-1
cd $firmware_path
touch_product_string=$(ls $touch_class_path)
echo "novatek"
firmware_file="novatek_ts-NT36675-21101302-6044-xpeng.bin"
touch_path=/sys$(cat $touch_class_path/$touch_product_string/path | awk '{print $1}')
wait_for_poweron
echo $firmware_file > $touch_path/doreflash
echo 1 > $touch_path/forcereflash
sleep 5
echo 1 > $touch_path/reset
