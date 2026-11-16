#include "power.hpp"

#include <Arduino.h>
#include <cstdio>

namespace gotcha {

namespace {

// D23 is P0.17 (~CHG). The BQ25101 drives it low while charging.
#ifndef PIN_BQ_CHG
#define PIN_BQ_CHG 23
#endif

// SAADC default: 0.6 V internal reference, gain 1/6, so 3.6 V full scale.
// 12-bit counts run 0..4095 across that range.
constexpr float kAdcFullScaleV = 3.6f;
constexpr float kAdcCounts = 4096.0f;
// Onboard divider: 1 MΩ over 510 kΩ.
constexpr float kDividerGain = 1510.0f / 510.0f;

} // namespace

void power_begin() {
  pinMode(VBAT_ENABLE, OUTPUT);
  digitalWrite(VBAT_ENABLE, LOW);
  pinMode(PIN_BQ_CHG, INPUT);
  analogReadResolution(12);
}

size_t power_format_sample(char* out, size_t out_cap) {
  if (out == nullptr || out_cap < 24) {
    return 0;
  }
  const uint32_t raw = analogRead(PIN_VBAT);
  const float volts = (static_cast<float>(raw) / kAdcCounts) * kAdcFullScaleV * kDividerGain;
  const unsigned charging = digitalRead(PIN_BQ_CHG) == LOW ? 1u : 0u;
  const int n = snprintf(out, out_cap, "$GSPWR,%.3f,%u*\r\n", static_cast<double>(volts), charging);
  if (n <= 0 || static_cast<size_t>(n) >= out_cap) {
    return 0;
  }
  return static_cast<size_t>(n);
}

} // namespace gotcha
