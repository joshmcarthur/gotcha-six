#include "status_led.hpp"

#include <Arduino.h>

namespace gotcha {

namespace {

// Common anode: analogWrite 0 is full on, 255 is off.
constexpr uint8_t kOff = 255;
constexpr uint8_t kDim = 16;

void rgb(uint8_t r, uint8_t g, uint8_t b) {
  analogWrite(LED_RED, kOff - r);
  analogWrite(LED_GREEN, kOff - g);
  analogWrite(LED_BLUE, kOff - b);
}

} // namespace

void status_led_begin() {
  pinMode(LED_RED, OUTPUT);
  pinMode(LED_GREEN, OUTPUT);
  pinMode(LED_BLUE, OUTPUT);
  status_led_off();
}

void status_led_off() {
  analogWrite(LED_RED, kOff);
  analogWrite(LED_GREEN, kOff);
  analogWrite(LED_BLUE, kOff);
  digitalWrite(LED_RED, HIGH);
  digitalWrite(LED_GREEN, HIGH);
  digitalWrite(LED_BLUE, HIGH);
}

void status_led_update(bool charging, bool ble_connected) {
  switch (status_led_mode(charging, ble_connected)) {
  case StatusLedMode::Charging: {
    const uint32_t phase = millis() % 2000;
    const uint8_t level = phase < 1000 ? static_cast<uint8_t>(phase * kDim / 1000)
                                       : static_cast<uint8_t>((2000 - phase) * kDim / 1000);
    rgb(level, static_cast<uint8_t>(level / 2), 0);
    break;
  }
  case StatusLedMode::Advertising:
    rgb(0, 0, (millis() % 1000) < 120 ? kDim : 0);
    break;
  case StatusLedMode::Off:
    status_led_off();
    break;
  }
}

} // namespace gotcha
