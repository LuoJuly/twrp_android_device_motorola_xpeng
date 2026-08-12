#
# Copyright (C) 2026 The Android Open Source Project
# Copyright (C) 2026 SebaUbuntu's TWRP device tree generator
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product-if-exists, $(SRC_TARGET_DIR)/product/embedded.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/languages_full.mk)

# Inherit from xpeng device
$(call inherit-product, device/motorola/xpeng/device.mk)

# Inherit some common TWRP stuff.
$(call inherit-product, vendor/twrp/config/common.mk)

PRODUCT_DEVICE := xpeng
PRODUCT_NAME := twrp_xpeng
PRODUCT_BRAND := motorola
PRODUCT_MODEL := XT2175
PRODUCT_MANUFACTURER := motorola

PRODUCT_GMS_CLIENTID_BASE := android-motorola

# Keep vendor fingerprint for keymaster env; OS display is Lineage/A16
PRODUCT_BUILD_PROP_OVERRIDES += \
    PRIVATE_BUILD_DESC="xpeng_g-user 12 S1RXS32.50-13-25 5fb68-c44485 release-keys"

BUILD_FINGERPRINT := motorola/xpeng_g/xpeng:12/S1RXS32.50-13-25/5fb68-c44485:user/release-keys

# Must be after inherit-product (single-value; last-ish override via product makefile)
PRODUCT_ENABLE_UFFD_GC := false
