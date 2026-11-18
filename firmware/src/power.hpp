#pragma once

#include <cstddef>
#include <cstdint>

namespace gotcha {

/// Enable the battery divider and leave it on. Seeed warns that driving
/// P0.14 high can put P0.31 near its 3.6 V limit.
void power_begin();

/// True while the BQ25101 drives P0.17 low.
bool power_charging();

/// Format one `$GSPWR,<volts>,<charging>*\r\n` into out.
/// Volts are the cell voltage. Charging is 1 when P0.17 is low.
/// Returns length, or 0 on failure.
size_t power_format_sample(char* out, size_t out_cap);

} // namespace gotcha
