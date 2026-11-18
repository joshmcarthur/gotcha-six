#pragma once

#include <cstdint>

namespace gotcha {

enum class StatusLedMode : uint8_t {
  Off,
  Advertising,
  Charging,
};

/// Charging wins. Otherwise on only while waiting for a BLE connection.
inline StatusLedMode status_led_mode(bool charging, bool ble_connected) {
  if (charging) {
    return StatusLedMode::Charging;
  }
  if (ble_connected) {
    return StatusLedMode::Off;
  }
  return StatusLedMode::Advertising;
}

void status_led_begin();
void status_led_update(bool charging, bool ble_connected);
void status_led_off();

} // namespace gotcha
