/*
 * Copyright (C) 2022 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
/*
 * Changes from Qualcomm Innovation Center are provided under the following license:
 * Copyright (c) 2023 Qualcomm Innovation Center, Inc. All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause-Clear
 */

#include "BootControl.h"

#include <cstdint>
#include <string>

#include <android-base/logging.h>

using HIDLMergeStatus = ::android::hardware::boot::V1_1::MergeStatus;
using ndk::ScopedAStatus;

namespace aidl::android::hardware::boot {

BootControl::BootControl() {
    if (!bootcontrol_init()) {
        LOG(ERROR) << "bootcontrol_init failed (start only after /dev/block is up)";
    }
}

ScopedAStatus BootControl::getActiveBootSlot(int32_t* _aidl_return) {
    int32_t ret = get_active_boot_slot();
    *_aidl_return = ret < 0 ? 0 : ret;
    return ScopedAStatus::ok();
}

ScopedAStatus BootControl::getCurrentSlot(int32_t* _aidl_return) {
    *_aidl_return = get_current_slot();
    return ScopedAStatus::ok();
}

ScopedAStatus BootControl::getNumberSlots(int32_t* _aidl_return) {
    *_aidl_return = get_number_slots();
    return ScopedAStatus::ok();
}

namespace {

static constexpr MergeStatus ToAIDLMergeStatus(HIDLMergeStatus status) {
    switch (status) {
        case HIDLMergeStatus::NONE:
            return MergeStatus::NONE;
        case HIDLMergeStatus::UNKNOWN:
            return MergeStatus::UNKNOWN;
        case HIDLMergeStatus::SNAPSHOTTED:
            return MergeStatus::SNAPSHOTTED;
        case HIDLMergeStatus::MERGING:
            return MergeStatus::MERGING;
        case HIDLMergeStatus::CANCELLED:
            return MergeStatus::CANCELLED;
        default:
            return MergeStatus::NONE;
    }
}

static constexpr HIDLMergeStatus ToHIDLMergeStatus(MergeStatus status) {
    switch (status) {
        case MergeStatus::NONE:
            return HIDLMergeStatus::NONE;
        case MergeStatus::UNKNOWN:
            return HIDLMergeStatus::UNKNOWN;
        case MergeStatus::SNAPSHOTTED:
            return HIDLMergeStatus::SNAPSHOTTED;
        case MergeStatus::MERGING:
            return HIDLMergeStatus::MERGING;
        case MergeStatus::CANCELLED:
            return HIDLMergeStatus::CANCELLED;
        default:
            return HIDLMergeStatus::NONE;
    }
}

}  // namespace

ScopedAStatus BootControl::getSnapshotMergeStatus(MergeStatus* _aidl_return) {
    *_aidl_return = ToAIDLMergeStatus(get_snapshot_merge_status());
    return ScopedAStatus::ok();
}

ScopedAStatus BootControl::getSuffix(int32_t in_slot, std::string* _aidl_return) {
    const char* suffix = get_suffix(in_slot);
    if (!suffix) {
        _aidl_return->clear();
    } else {
        *_aidl_return = suffix;
    }
    return ScopedAStatus::ok();
}

ScopedAStatus BootControl::isSlotBootable(int32_t in_slot, bool* _aidl_return) {
    int32_t ret = is_slot_bootable(in_slot);
    if (ret < 0) {
        return ScopedAStatus::fromServiceSpecificErrorWithMessage(
                INVALID_SLOT, (std::string("Invalid slot ") + std::to_string(in_slot)).c_str());
    }
    *_aidl_return = ret != 0;
    return ScopedAStatus::ok();
}

ScopedAStatus BootControl::isSlotMarkedSuccessful(int32_t in_slot, bool* _aidl_return) {
    int32_t ret = is_slot_marked_successful(in_slot);
    if (ret < 0) {
        return ScopedAStatus::fromServiceSpecificErrorWithMessage(
                INVALID_SLOT, (std::string("Invalid slot ") + std::to_string(in_slot)).c_str());
    }
    *_aidl_return = ret != 0;
    return ScopedAStatus::ok();
}

ScopedAStatus BootControl::markBootSuccessful() {
    if (mark_boot_successful() == 0) {
        return ScopedAStatus::ok();
    }
    return ScopedAStatus::fromServiceSpecificErrorWithMessage(COMMAND_FAILED, "Operation failed");
}

ScopedAStatus BootControl::setActiveBootSlot(int32_t in_slot) {
    if (set_active_boot_slot(in_slot) == 0) {
        return ScopedAStatus::ok();
    }
    return ScopedAStatus::fromServiceSpecificErrorWithMessage(COMMAND_FAILED, "Operation failed");
}

ScopedAStatus BootControl::setSlotAsUnbootable(int32_t in_slot) {
    if (set_slot_as_unbootable(in_slot) == 0) {
        return ScopedAStatus::ok();
    }
    return ScopedAStatus::fromServiceSpecificErrorWithMessage(COMMAND_FAILED, "Operation failed");
}

ScopedAStatus BootControl::setSnapshotMergeStatus(MergeStatus in_status) {
    if (!set_snapshot_merge_status(ToHIDLMergeStatus(in_status))) {
        return ScopedAStatus::fromServiceSpecificErrorWithMessage(COMMAND_FAILED,
                                                                  "Operation failed");
    }
    return ScopedAStatus::ok();
}

}  // namespace aidl::android::hardware::boot
