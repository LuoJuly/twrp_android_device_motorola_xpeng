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
BOARD_SYSTEMIMAGE_PARTITION_TYPE := ext4
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4
TARGET_COPY_OUT_VENDOR := vendor
BOARD_SUPER_PARTITION_SIZE := 9126805504 # TODO: Fix hardcoded value
BOARD_SUPER_PARTITION_GROUPS := motorola_dynamic_partitions
BOARD_MOTOROLA_DYNAMIC_PARTITIONS_PARTITION_LIST := system system_ext product vendor odm
BOARD_MOTOROLA_DYNAMIC_PARTITIONS_SIZE := 9122611200 # TODO: Fix hardcoded value

# Platform
TARGET_BOARD_PLATFORM := lahaina

# Recovery
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true

# Security patch level
VENDOR_SECURITY_PATCH := 2021-08-01

# Verified Boot
BOARD_AVB_ENABLE := true
BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --flags 3

# Hack: prevent anti rollback
PLATFORM_SECURITY_PATCH := 2099-12-31
VENDOR_SECURITY_PATCH := 2099-12-31
PLATFORM_VERSION := 16.1.0

# TWRP Configuration
# portrait_hdpi (1080x1920) scaled to 1080x2460 — best stock theme for this panel
TW_THEME := portrait_hdpi
TW_EXTRA_LANGUAGES := true
TW_SCREEN_BLANK_ON_BOOT := true
TW_INPUT_BLACKLIST := "hbtp_vm"
TW_USE_TOOLBOX := true
TW_INCLUDE_REPACKTOOLS := true
# Read capacity from sysfs (built-in qti_battery_charger -> battery).
# Without this, health HAL failure defaults the UI to a fake 100%.
TW_USE_LEGACY_BATTERY_SERVICES := true
# Published by recovery/root/system/bin/init_thermal.sh (zone0 is often
# missing/unreadable until ADSP/QMI sensors come up on lahaina).
TW_CUSTOM_CPU_TEMP_PATH := /tmp/twrp_cpu_temp

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
