#pragma once

#include <cstddef>
#include <cstdint>

namespace gotcha {

bool imu_begin();
/// Format one `$GSIMU,...*\r\n` into out. Returns length, or 0 if not ready / failed.
size_t imu_format_sample(char* out, size_t out_cap);

} // namespace gotcha
