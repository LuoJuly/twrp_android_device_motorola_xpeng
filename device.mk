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

# Virtual A/B — stock xpeng super is virtual_ab_device (one slot + COW).
# Without this, update_engine_sideload treats super as classic A/B and
# rejects full-slot groups (~8GB > super/2).
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota.mk)

# A/B
AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_system=true \
    POSTINSTALL_PATH_system=system/bin/otapreopt_script \
    FILESYSTEM_TYPE_system=ext4 \
    POSTINSTALL_OPTIONAL_system=true

# Boot control HAL — recovery must ship a passthrough impl (decrypt checkpoint
# waits on IBootControl). Use QTI with Motorola dual-LUN GPT (sdd=_a, sdf=_b)
# plus UFS boot LUN; AOSP impl only writes /misc, which Motorola ABL ignores.
# Same .so stem as AOSP so 1.2-service loads it.
PRODUCT_PACKAGES += \
    android.hardware.boot@1.2-impl-qti \
    android.hardware.boot@1.2-impl-qti.recovery \
    android.hardware.boot@1.2-service

PRODUCT_PACKAGES += \
    update_engine_sideload \
    update_verifier

# QCOM FBE decryption (device/qcom/twrp-common)
PRODUCT_PACKAGES += \
    qcom_decrypt \
    qcom_decrypt_fbe

# QTI AIDL vibrator HAL (copied into recovery via BoardConfig RECOVERY_*_SOURCE_FILES)
PRODUCT_PACKAGES += \
    vendor.qti.hardware.vibrator.service
