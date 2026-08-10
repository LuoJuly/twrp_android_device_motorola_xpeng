#
# Copyright (C) 2026 The Android Open Source Project
# Copyright (C) 2026 SebaUbuntu's TWRP device tree generator
#
# SPDX-License-Identifier: Apache-2.0
#

DEVICE_PATH := device/motorola/xpeng

# For building with minimal manifest
ALLOW_MISSING_DEPENDENCIES := true

# A/B
AB_OTA_UPDATER := true
AB_OTA_PARTITIONS += \
    system \
    product \
    system_ext \
    vendor \
    odm
BOARD_USES_RECOVERY_AS_BOOT := true

# Architecture
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 := 
TARGET_CPU_VARIANT := generic
TARGET_CPU_VARIANT_RUNTIME := kryo300

TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv7-a-neon
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := generic
TARGET_2ND_CPU_VARIANT_RUNTIME := cortex-a75

# APEX
DEXPREOPT_GENERATE_APEX_IMAGE := true

# Bootloader
TARGET_BOOTLOADER_BOARD_NAME := xpeng
TARGET_NO_BOOTLOADER := true

# Display (panel 1080x2460; density left unchanged)
TARGET_SCREEN_WIDTH := 1080
TARGET_SCREEN_HEIGHT := 2460
TARGET_SCREEN_DENSITY := 400

# Kernel
BOARD_BOOTIMG_HEADER_VERSION := 3
BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOTIMG_HEADER_VERSION)
BOARD_KERNEL_IMAGE_NAME := Image
TARGET_KERNEL_CONFIG := xpeng_defconfig
TARGET_KERNEL_SOURCE := kernel/motorola/xpeng

# Kernel - prebuilt
TARGET_FORCE_PREBUILT_KERNEL := true
ifeq ($(TARGET_FORCE_PREBUILT_KERNEL),true)
TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilt/kernel
endif

# Partitions
BOARD_BOOTIMAGE_PARTITION_SIZE := 100663296
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 100663296
BOARD_HAS_LARGE_FILESYSTEM := true
# Build-time types (on-device logical partitions probed as ext4)
BOARD_SYSTEMIMAGE_PARTITION_TYPE := ext4
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := f2fs
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4
TARGET_COPY_OUT_VENDOR := vendor
BOARD_SUPER_PARTITION_SIZE := 9126805504 # TODO: Fix hardcoded value
BOARD_SUPER_PARTITION_GROUPS := motorola_dynamic_partitions
BOARD_MOTOROLA_DYNAMIC_PARTITIONS_PARTITION_LIST := system system_ext product vendor odm
BOARD_MOTOROLA_DYNAMIC_PARTITIONS_SIZE := 9122611200 # TODO: Fix hardcoded value

# Platform
TARGET_BOARD_PLATFORM := lahaina
QCOM_BOARD_PLATFORMS += lahaina

# Recovery
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery.fstab
RECOVERY_SDCARD_ON_DATA := true

# Verified Boot
BOARD_AVB_ENABLE := true
BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --flags 3

# Encryption / FBE (stock A12: wrappedkey_v0 + metadata keydirectory)
BOARD_USES_METADATA_PARTITION := true
BOARD_USES_QCOM_FBE_DECRYPTION := true
TW_INCLUDE_CRYPTO := true
TW_INCLUDE_CRYPTO_FBE := true
TW_INCLUDE_FBE_METADATA_DECRYPT := true
TW_USE_FSCRYPT_POLICY := 2
# Manifest has @4.1 but TWRP maps any "4*" → keymaster_ver=4.x, which starts
# BOTH 4.0 and 4.1 HALs as "default" and races km_compat / keystore2.
TW_FORCE_KEYMASTER_VER := true
TW_INCLUDE_RESETPROP := true
TW_EXCLUDE_APEX := true
# Needed to see keystore2/km_compat abort reasons in recovery
TWRP_INCLUDE_LOGCAT := true
TARGET_USES_LOGD := true
# Match qcom prepdecrypt defaults; real patch pulled from system/vendor when possible
PLATFORM_VERSION := 99.87.36
PLATFORM_VERSION_LAST_STABLE := $(PLATFORM_VERSION)
PLATFORM_SECURITY_PATCH := 2099-12-31
VENDOR_SECURITY_PATCH := 2099-12-31

# libs required by qseecomd / keymaster (missing libion caused splash hang)
TARGET_RECOVERY_DEVICE_MODULES += libion
RECOVERY_LIBRARY_SOURCE_FILES += $(TARGET_OUT_SHARED_LIBRARIES)/libion.so

# TWRP Configuration
# portrait_hdpi (1080x1920) scaled to 1080x2460 — best stock theme for this panel
# Shown as: 3.7.1_12-<TW_DEVICE_VERSION>
_empty :=
_space := $(_empty) $(_empty)
TW_DEVICE_VERSION := 0_by$(_space)LuoJuly
TW_THEME := portrait_hdpi
TW_EXTRA_LANGUAGES := true
TW_SCREEN_BLANK_ON_BOOT := true
TW_INPUT_BLACKLIST := "hbtp_vm"
TW_USE_TOOLBOX := true
TW_INCLUDE_REPACKTOOLS := true
# lahaina RTC ticks from 1970; real time = rtc + /data/vendor/time/ats_*
TARGET_RECOVERY_QCOM_RTC_FIX := true
# POSIX UTC+8 (Beijing, no DST). Wired through recovery Android.mk → data.cpp.
TW_DEFAULT_TIMEZONE := CST-8
# Keep MTP off (breaks ADB on this configfs gadget). USB mass storage (UMS)
# is enabled separately via mass_storage.0 lun in init.recovery.usb.rc.
TW_EXCLUDE_MTP := true
# Legacy sysfs battery (health HAL failure previously faked 100%).
# Capacity/status published by init_thermal.sh — direct battery/capacity is
# often unreadable early, which makes tw_battery="-1%" and hides the widget.
TW_USE_LEGACY_BATTERY_SERVICES := true
TW_CUSTOM_BATTERY_PATH := /tmp/twrp_battery
# Published by init_thermal.sh (zone0 often missing until ADSP/QMI is up).
TW_CUSTOM_CPU_TEMP_PATH := /tmp/twrp_cpu_temp
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true

# -----------------------------------------------------------------------------
# Touch (Novatek + mmi) for recovery
# Primary path: recovery/root/{vendor/lib/modules,vendor/firmware,system/bin}
# + init.recovery.qcom.rc exec /system/bin/runatboot (insmod -f for vermagic skew)
#
# TW_LOAD_VENDOR_MODULES uses modprobe (no -f) and is NOT sufficient alone when
# .ko vermagic != prebuilt/kernel release. Keep it commented unless modules are
# rebuilt against this exact Image.
#
# TW_LOAD_VENDOR_MODULES := "mmi_annotate.ko mmi_relay.ko sensors_class.ko touchscreen_mmi.ko nova_0flash_mmi.ko"
# TW_LOAD_VENDOR_MODULES_EXCLUDE_GKI := true
# -----------------------------------------------------------------------------

TARGET_SYSTEM_PROP += $(DEVICE_PATH)/system.prop
