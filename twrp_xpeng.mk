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

# Inherit some common Omni stuff.
#$(call inherit-product, vendor/omni/config/common.mk)

# Inherit from xpeng device
$(call inherit-product, device/motorola/xpeng/device.mk)

# Inherit some common TWRP stuff.
$(call inherit-product, vendor/twrp/config/common.mk)
#$(call inherit-product, vendor/twrp/config/gsm.mk)

PRODUCT_DEVICE := xpeng
PRODUCT_NAME := twrp_xpeng
PRODUCT_BRAND := motorola
PRODUCT_MODEL := XT2175-2
PRODUCT_MANUFACTURER := motorola

# enable the FRP addon
OF_ENABLE_FRP_ADDON := 1

PRODUCT_GMS_CLIENTID_BASE := android-motorola

PRODUCT_BUILD_PROP_OVERRIDES += \
    PRIVATE_BUILD_DESC="xpeng_retcn-user 11 S3RXC32.33-8-29 99146a release-keys"

BUILD_FINGERPRINT := motorola/xpeng_retcn/xpeng:11/S3RXC32.33-8-29/99146a:user/release-keys
