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
    vendor
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

# Large recovery ramdisk panics this KernelSU Image in unpack_to_rootfs.
# Prefer LZ4 + aggressive size cuts (target ~OEM unc ~25MB).
BOARD_RAMDISK_USE_LZ4 := true
TW_EXCLUDE_BASH := true
TW_EXCLUDE_NANO := true
TW_NO_EXFAT := true
TW_NO_EXFAT_FUSE := true
TW_INCLUDE_REPACKTOOLS := false
TW_EXCLUDE_TZDATA := true
# Drop logd/logcat from ramdisk (~1MB); use pstore /adb when needed.
TWRP_INCLUDE_LOGCAT := false
TARGET_USES_LOGD := false
# Late slim immediately before mkbootfs (after all recovery installs).
BOARD_RECOVERY_IMAGE_PREPARE := $(DEVICE_PATH)/recovery/slim-ramdisk.sh

# Partitions
BOARD_BOOTIMAGE_PARTITION_SIZE := 100663296
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 100663296
BOARD_HAS_LARGE_FILESYSTEM := true
# Build-time types: match tundra (erofs). Runtime mount still uses dual fstab.
BOARD_SYSTEMIMAGE_PARTITION_TYPE := erofs
BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_SYSTEM_EXTIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_PRODUCTIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := f2fs
TARGET_COPY_OUT_VENDOR := vendor
TARGET_COPY_OUT_PRODUCT := product
TARGET_COPY_OUT_SYSTEM_EXT := system_ext
# Match LineageOS / stock xpeng super (8 GiB) and mot_dp_group naming so
# update_engine_sideload can prepare Virtual A/B metadata for official OTAs.
BOARD_SUPER_PARTITION_SIZE := 8589934592
BOARD_SUPER_PARTITION_GROUPS := mot_dp_group
BOARD_MOT_DP_GROUP_SIZE := 8585740288 # SUPER - 4MiB
# No odm: this ROM has no odm mapper (matches recovery.fstab).
BOARD_MOT_DP_GROUP_PARTITION_LIST := system system_ext product vendor

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
# Match qcom prepdecrypt defaults; real patch pulled from system/vendor when possible
PLATFORM_VERSION := 99.87.36
PLATFORM_VERSION_LAST_STABLE := $(PLATFORM_VERSION)
PLATFORM_SECURITY_PATCH := 2099-12-31
VENDOR_SECURITY_PATCH := 2099-12-31

# libs required by qseecomd / keymaster (missing libion caused splash hang)
TARGET_RECOVERY_DEVICE_MODULES += libion
RECOVERY_LIBRARY_SOURCE_FILES += $(TARGET_OUT_SHARED_LIBRARIES)/libion.so

# QTI AIDL vibrator (qcom-hv-haptics input FF) — ship HAL into recovery ramdisk
TW_SUPPORT_INPUT_AIDL_HAPTICS := true
TW_SUPPORT_INPUT_AIDL_HAPTICS_FIX_OFF := true
# Soong knobs expected by vendor/qcom/opensource/vibrator (twrp-14.1)
SOONG_CONFIG_NAMESPACES += qti_vibrator vibrator
SOONG_CONFIG_qti_vibrator += use_effect_stream effect_lib
SOONG_CONFIG_qti_vibrator_use_effect_stream := false
SOONG_CONFIG_qti_vibrator_effect_lib := libqtivibratoreffect
SOONG_CONFIG_vibrator += vibratortargets
# A14 uses -ndk (not -ndk_platform)
SOONG_CONFIG_vibrator_vibratortargets := vibratoraidlV2target
TARGET_RECOVERY_DEVICE_MODULES += \
    vendor.qti.hardware.vibrator.service \
    vendor.qti.hardware.vibrator.impl \
    libqtivibratoreffect
RECOVERY_BINARY_SOURCE_FILES += \
    $(TARGET_OUT_VENDOR_EXECUTABLES)/hw/vendor.qti.hardware.vibrator.service
RECOVERY_LIBRARY_SOURCE_FILES += \
    $(TARGET_OUT_VENDOR_SHARED_LIBRARIES)/vendor.qti.hardware.vibrator.impl.so \
    $(TARGET_OUT_VENDOR_SHARED_LIBRARIES)/libqtivibratoreffect.so

# TWRP Configuration
# portrait_hdpi (1080x1920) scaled to 1080x2460 — best stock theme for this panel
# Shown as: 3.7.1_14-<TW_DEVICE_VERSION> on twrp-14.1
_empty :=
_space := $(_empty) $(_empty)
TW_DEVICE_VERSION := 0_by$(_space)LuoJuly
TW_THEME := portrait_hdpi
# Languages pruned in slim-ramdisk.sh to en + zh_CN; skip shipping the full set.
TW_EXTRA_LANGUAGES := false
TW_SCREEN_BLANK_ON_BOOT := true
TW_INPUT_BLACKLIST := "hbtp_vm"
TW_USE_TOOLBOX := true
# Enable password-encrypted TWRP backups (openaes). Must be non-empty and not
# the string "true" — see bootable/recovery/Android.mk + openaes/Android.mk.
TW_EXCLUDE_ENCRYPTED_BACKUPS := false
# lahaina RTC ticks from 1970; real time = rtc + /data/vendor/time/ats_*
TARGET_RECOVERY_QCOM_RTC_FIX := true
# POSIX UTC+8 (Beijing, no DST). Wired through recovery Android.mk → data.cpp.
TW_DEFAULT_TIMEZONE := CST-8
# MTP via configfs ffs.mtp (see init.recovery.usb.rc). UMS remains mass_storage.0.
# Do NOT set TW_EXCLUDE_MTP.
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
