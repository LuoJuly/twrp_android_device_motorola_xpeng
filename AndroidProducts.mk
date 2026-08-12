#
# Copyright (C) 2026 The Android Open Source Project
# Copyright (C) 2026 SebaUbuntu's TWRP device tree generator
#
# SPDX-License-Identifier: Apache-2.0
#

PRODUCT_MAKEFILES := \
    $(LOCAL_DIR)/twrp_xpeng.mk

# Android 14+ lunch form: <product>-<release>-<variant>
COMMON_LUNCH_CHOICES := \
    twrp_xpeng-ap2a-user \
    twrp_xpeng-ap2a-userdebug \
    twrp_xpeng-ap2a-eng
