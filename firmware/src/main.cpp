#include <Arduino.h>
#include <bluefruit.h>

#include "bridge.hpp"
#include "imu.hpp"

namespace {

gotcha::Bridge bridge;
BLEUart bleuart;
BLEDis bledis;

constexpr uint32_t kImuPeriodMs = 40;  // 25 Hz
uint32_t last_imu_ms = 0;
bool imu_ok = false;

void start_advertising() {
  Bluefruit.Advertising.addFlags(BLE_GAP_ADV_FLAGS_LE_ONLY_GENERAL_DISC_MODE);
  Bluefruit.Advertising.addTxPower();
  Bluefruit.Advertising.addService(bleuart);
  Bluefruit.ScanResponse.addName();
  Bluefruit.Advertising.restartOnDisconnect(true);
  Bluefruit.Advertising.setInterval(32, 244);
  Bluefruit.Advertising.setFastTimeout(30);
  Bluefruit.Advertising.start(0);
}

void connect_callback(uint16_t conn_handle) {
  BLEConnection* conn = Bluefruit.Connection(conn_handle);
  if (conn) {
    conn->requestMtuExchange(247);
  }
}

void disconnect_callback(uint16_t conn_handle, uint8_t reason) {
  (void)conn_handle;
  (void)reason;
  // USB and UART keep running; advertising restarts via restartOnDisconnect.
}

void drain_radar_to_fifos() {
  while (Serial1.available() > 0) {
    bridge.on_radar_byte(static_cast<uint8_t>(Serial1.read()));
  }
}

void drain_usb_host() {
  while (Serial.available() > 0) {
    bridge.on_host_byte(gotcha::HostSource::Usb, static_cast<uint8_t>(Serial.read()));
  }
}

void drain_ble_host() {
  while (bleuart.available() > 0) {
    bridge.on_host_byte(gotcha::HostSource::Ble, static_cast<uint8_t>(bleuart.read()));
  }
}

void service_radar_tx() {
  while (Serial1.availableForWrite() > 0) {
    uint8_t b;
    if (!bridge.pop_cmd_byte(b)) {
      break;
    }
    Serial1.write(b);
  }
}

void service_usb_tx() {
  uint8_t buf[64];
  while (true) {
    int space = Serial.availableForWrite();
    if (space <= 0) {
      break;
    }
    size_t n = bridge.usb_fifo().pop(buf, static_cast<size_t>(space) < sizeof(buf)
                                               ? static_cast<size_t>(space)
                                               : sizeof(buf));
    if (n == 0) {
      break;
    }
    Serial.write(buf, n);
  }
}

void service_ble_tx() {
  if (!Bluefruit.connected() || !bleuart.notifyEnabled()) {
    return;
  }
  BLEConnection* conn = Bluefruit.Connection(Bluefruit.connHandle());
  if (!conn) {
    return;
  }
  const uint16_t chunk = conn->getMtu() > 3 ? static_cast<uint16_t>(conn->getMtu() - 3) : 20;
  uint8_t buf[244];
  const size_t max_chunk = chunk < sizeof(buf) ? chunk : sizeof(buf);

  while (bridge.ble_fifo().count() > 0) {
    size_t n = bridge.ble_fifo().peek(buf, max_chunk);
    if (n == 0) {
      break;
    }
    size_t written = bleuart.write(buf, n);
    if (written == 0) {
      break;
    }
    bridge.ble_fifo().discard(written);
    if (written < n) {
      break;
    }
  }
}

void maybe_imu_sample() {
  if (!imu_ok) {
    return;
  }
  const uint32_t now = millis();
  if (now - last_imu_ms < kImuPeriodMs) {
    return;
  }
  last_imu_ms = now;

  char line[96];
  size_t n = gotcha::imu_format_sample(line, sizeof(line));
  if (n == 0) {
    return;
  }
  const bool ble_ok = Bluefruit.connected() && bleuart.notifyEnabled();
  (void)bridge.inject_host_line(reinterpret_cast<const uint8_t*>(line), n, ble_ok);
}

}  // namespace

void setup() {
  Serial.begin(115200);
  // Do not wait for Serial — that would block BLE when no USB host is present.

  Serial1.begin(9600);

  Bluefruit.begin();
  Bluefruit.setName("Gotcha Six");
  Bluefruit.setTxPower(4);
  Bluefruit.Periph.setConnectCallback(connect_callback);
  Bluefruit.Periph.setDisconnectCallback(disconnect_callback);

  bledis.setManufacturer("Gotcha Six");
  bledis.setModel("XIAO nRF52840 Sense");
  bledis.begin();

  bleuart.begin();
  bleuart.bufferTXD(true);

  start_advertising();

  imu_ok = gotcha::imu_begin();
}

void loop() {
  drain_radar_to_fifos();
  drain_usb_host();   // USB first for command arbitration
  drain_ble_host();
  service_radar_tx();
  maybe_imu_sample();
  service_usb_tx();
  service_ble_tx();
}
