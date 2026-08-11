#
# Recovery helpers for xpeng. Late ramdisk slim is hooked via
# BOARD_RECOVERY_IMAGE_PREPARE (see BoardConfig.mk) so it runs after all
# installs and immediately before mkbootfs.
#
LOCAL_PATH := $(call my-dir)
