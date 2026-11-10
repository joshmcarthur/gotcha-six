#include <unity.h>

#include <cstring>

#include "bridge.hpp"

using gotcha::Bridge;
using gotcha::HostSource;

void setUp() {}
void tearDown() {}

void test_radar_fans_out_to_usb_and_ble() {
  Bridge b;
  const char* msg = "$DFDMD,1,1,1.0,0.1,10, , *\n";
  for (const char* p = msg; *p; ++p) {
    b.on_radar_byte(static_cast<uint8_t>(*p));
  }
  TEST_ASSERT_EQUAL(std::strlen(msg), b.usb_fifo().count());
  TEST_ASSERT_EQUAL(std::strlen(msg), b.ble_fifo().count());

  uint8_t buf[64];
  size_t n = b.usb_fifo().pop(buf, sizeof(buf));
  TEST_ASSERT_EQUAL(std::strlen(msg), n);
  TEST_ASSERT_EQUAL_STRING_LEN(msg, reinterpret_cast<char*>(buf), n);
}

void test_usb_command_enqueues_crlf() {
  Bridge b;
  const char* cmd = "sensorStop";
  for (const char* p = cmd; *p; ++p) {
    b.on_host_byte(HostSource::Usb, static_cast<uint8_t>(*p));
  }
  b.on_host_byte(HostSource::Usb, '\n');

  char out[32] = {};
  size_t i = 0;
  uint8_t byte;
  while (b.pop_cmd_byte(byte) && i + 1 < sizeof(out)) {
    out[i++] = static_cast<char>(byte);
  }
  TEST_ASSERT_EQUAL_STRING("sensorStop\r\n", out);
}

void test_usb_before_ble_ordering() {
  Bridge b;
  // Complete USB line then BLE line — USB must appear first on cmd queue.
  for (const char* p = "usbCmd"; *p; ++p) {
    b.on_host_byte(HostSource::Usb, static_cast<uint8_t>(*p));
  }
  b.on_host_byte(HostSource::Usb, '\n');
  for (const char* p = "bleCmd"; *p; ++p) {
    b.on_host_byte(HostSource::Ble, static_cast<uint8_t>(*p));
  }
  b.on_host_byte(HostSource::Ble, '\n');

  char out[64] = {};
  size_t i = 0;
  uint8_t byte;
  while (b.pop_cmd_byte(byte) && i + 1 < sizeof(out)) {
    out[i++] = static_cast<char>(byte);
  }
  TEST_ASSERT_EQUAL_STRING("usbCmd\r\nbleCmd\r\n", out);
}

void test_oversize_line_dropped() {
  Bridge b;
  for (size_t i = 0; i < gotcha::kLineMax + 10; ++i) {
    b.on_host_byte(HostSource::Usb, 'A');
  }
  b.on_host_byte(HostSource::Usb, '\n');
  uint8_t byte;
  TEST_ASSERT_FALSE(b.pop_cmd_byte(byte));
}

void test_imu_inject_skips_ble_when_high_water() {
  Bridge b;
  // Fill BLE above 75%.
  while (b.ble_fifo().count() * 4 <= b.ble_fifo().capacity() * 3) {
    TEST_ASSERT_TRUE(b.ble_fifo().push(static_cast<uint8_t>('x')));
  }
  const char* imu = "$GSIMU,0,0,9.8,0,0,0*\r\n";
  bool ble_accepted =
      b.inject_host_line(reinterpret_cast<const uint8_t*>(imu), std::strlen(imu), true);
  TEST_ASSERT_FALSE(ble_accepted);
  // USB still got it.
  TEST_ASSERT_TRUE(b.usb_fifo().count() >= std::strlen(imu));
}

void test_ble_make_room_prefers_gsimu() {
  Bridge b;
  const char* imu = "$GSIMU,1,2,3,4,5,6*\n";
  const char* radar = "$DFHPD,1, , , *\n";
  for (const char* p = imu; *p; ++p) {
    TEST_ASSERT_TRUE(b.ble_fifo().push(static_cast<uint8_t>(*p)));
  }
  for (const char* p = radar; *p; ++p) {
    TEST_ASSERT_TRUE(b.ble_fifo().push(static_cast<uint8_t>(*p)));
  }
  b.ble_make_room(b.ble_fifo().capacity());  // force drops
  // After dropping GSIMU line, remaining should start with $DFHPD or be empty.
  if (!b.ble_fifo().empty()) {
    TEST_ASSERT_FALSE(b.ble_fifo().starts_with_gsimu());
  }
}

int main(int argc, char** argv) {
  (void)argc;
  (void)argv;
  UNITY_BEGIN();
  RUN_TEST(test_radar_fans_out_to_usb_and_ble);
  RUN_TEST(test_usb_command_enqueues_crlf);
  RUN_TEST(test_usb_before_ble_ordering);
  RUN_TEST(test_oversize_line_dropped);
  RUN_TEST(test_imu_inject_skips_ble_when_high_water);
  RUN_TEST(test_ble_make_room_prefers_gsimu);
  return UNITY_END();
}
