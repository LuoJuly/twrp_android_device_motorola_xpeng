#
# Copyright (C) 2026 The Android Open Source Project
# Copyright (C) 2026 SebaUbuntu's TWRP device tree generator
#
# SPDX-License-Identifier: Apache-2.0
#

LOCAL_PATH := device/motorola/xpeng

# Export this device Soong namespace so PRODUCT_PACKAGES can see
# android.hardware.boot@1.2-impl-qti (device Android.bp is namespaced).
PRODUCT_SOONG_NAMESPACES += \
    device/motorola/xpeng \
    device/qcom/common/gpt-utils

PRODUCT_USE_DYNAMIC_PARTITIONS := true

# Virtual A/B — same as Lineage sm7325-common (virtual_ab_ota.mk).
# Critical for A/B zip sideload space checks (super holds one slot + COW).
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota/launch_with_vendor_ramdisk.mk)

# A/B
AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_system=true \
    POSTINSTALL_PATH_system=system/bin/otapreopt_script \
    FILESYSTEM_TYPE_system=ext4 \
    POSTINSTALL_OPTIONAL_system=true

# Boot control HAL — QTI dual-LUN GPT (sdd=_a, sdf=_b) + UFS boot LUN.
# Recovery uses Lineage-style AIDL android.hardware.boot-service.qti.recovery
# (system libs only). Do not ship HIDL @1.2-service: it dlopens
# /vendor/lib64/hw and blocks Format Data unmap of vendor_b.
PRODUCT_PACKAGES += \
    android.hardware.boot-service.qti.recovery

# Keep update_engine_sideload (A/B zip). Omit update_verifier / fastbootd (ramdisk).
PRODUCT_PACKAGES += \
    update_engine_sideload

# QCOM FBE decryption (device/qcom/twrp-common)
PRODUCT_PACKAGES += \
    qcom_decrypt \
    qcom_decrypt_fbe

# QTI AIDL vibrator HAL (copied into recovery via BoardConfig RECOVERY_*_SOURCE_FILES)
PRODUCT_PACKAGES += \
    vendor.qti.hardware.vibrator.service \
    libexpat

# Prebuilt recovery bins (magiskboot etc.) may be 4K-aligned
PRODUCT_CHECK_PREBUILT_MAX_PAGE_SIZE := false

# Kernel 5.4: no UFFD GC
PRODUCT_ENABLE_UFFD_GC := false
