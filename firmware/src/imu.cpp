#include "imu.hpp"

#include <Adafruit_LSM6DS3TRC.h>
#include <Wire.h>
#include <cstdio>

namespace gotcha {

namespace {

Adafruit_LSM6DS3TRC imu;
bool ready = false;

#ifndef PIN_LSM6DS3TR_C_POWER
// Seeed XIAO nRF52840 Sense (Adafruit / Seeed nRF52 boards numbering).
#define PIN_LSM6DS3TR_C_POWER 15
#endif

}  // namespace

bool imu_begin() {
  pinMode(PIN_LSM6DS3TR_C_POWER, OUTPUT);
  digitalWrite(PIN_LSM6DS3TR_C_POWER, HIGH);
  delay(10);

  Wire1.begin();
  if (!imu.begin_I2C(LSM6DS_I2CADDR_DEFAULT, &Wire1)) {
    ready = false;
    return false;
  }
  imu.setAccelDataRate(LSM6DS_RATE_52_HZ);
  imu.setGyroDataRate(LSM6DS_RATE_52_HZ);
  ready = true;
  return true;
}

size_t imu_format_sample(char* out, size_t out_cap) {
  if (!ready || out == nullptr || out_cap < 48) {
    return 0;
  }
  sensors_event_t accel;
  sensors_event_t gyro;
  sensors_event_t temp;
  imu.getEvent(&accel, &gyro, &temp);

  // Adafruit gives accel in m/s^2 and gyro in rad/s.
  int n = snprintf(out, out_cap, "$GSIMU,%.3f,%.3f,%.3f,%.4f,%.4f,%.4f*\r\n",
                   accel.acceleration.x, accel.acceleration.y, accel.acceleration.z,
                   gyro.gyro.x, gyro.gyro.y, gyro.gyro.z);
  if (n <= 0 || static_cast<size_t>(n) >= out_cap) {
    return 0;
  }
  return static_cast<size_t>(n);
}

}  // namespace gotcha
