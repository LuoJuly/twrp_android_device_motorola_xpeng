#
# Copyright (C) 2026 The Android Open Source Project
# Copyright (C) 2026 SebaUbuntu's TWRP device tree generator
#
# SPDX-License-Identifier: Apache-2.0
#

LOCAL_PATH := device/motorola/xpeng

PRODUCT_USE_DYNAMIC_PARTITIONS := true

# A/B
AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_system=true \
    POSTINSTALL_PATH_system=system/bin/otapreopt_script \
    FILESYSTEM_TYPE_system=ext4 \
    POSTINSTALL_OPTIONAL_system=true

# Boot control HAL — recovery must ship the passthrough impl.
# Decrypt_Data → MetadataCrypt → cp_needsCheckpoint() → IBootControl::getService()
# waits forever if boot-hal cannot load android.hardware.boot@1.0-impl-1.2.so
# (symptoms: stuck on TWRP splash, logspam "Waited one second for IBootControl").
PRODUCT_PACKAGES += \
    android.hardware.boot@1.2-impl \
    android.hardware.boot@1.2-impl.recovery \
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
