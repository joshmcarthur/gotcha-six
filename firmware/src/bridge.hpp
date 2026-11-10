#pragma once

#include <cstddef>
#include <cstdint>

namespace gotcha {

constexpr size_t kUsbFifoSize = 2048;
constexpr size_t kBleFifoSize = 2048;
constexpr size_t kCmdQueueSize = 512;
constexpr size_t kLineMax = 128;

enum class HostSource : uint8_t { Usb = 0, Ble = 1 };

/// Byte ring buffer. Drop policy is chosen by the caller.
class RingBuffer {
 public:
  explicit RingBuffer(uint8_t* storage, size_t capacity);

  size_t capacity() const { return capacity_; }
  size_t count() const;
  size_t free_space() const { return capacity_ - count(); }
  bool empty() const { return count() == 0; }
  bool full() const { return count() == capacity_; }

  /// Push one byte. Returns false if full (no write).
  bool push(uint8_t b);
  /// Push bytes; returns number written (may be short if full).
  size_t push(const uint8_t* data, size_t len);
  /// Drop oldest byte if present; return true if dropped.
  bool drop_oldest();
  bool pop(uint8_t& out);
  size_t pop(uint8_t* out, size_t max_len);
  /// Copy up to max_len bytes without removing them.
  size_t peek(uint8_t* out, size_t max_len) const;
  /// Discard up to n oldest bytes.
  size_t discard(size_t n);
  void clear();

  /// True if the buffer starts with ASCII "$GSIMU" (for drop preference).
  bool starts_with_gsimu() const;

 private:
  uint8_t* storage_;
  size_t capacity_;
  size_t head_;
  size_t tail_;
  size_t count_;
};

/// Dual-host line arbiter and fan-out state (no Arduino types).
class Bridge {
 public:
  Bridge();

  /// Radar UART RX byte: copy into USB and BLE FIFOs.
  void on_radar_byte(uint8_t b);

  /// Inject a complete line (already including trailing \n) into USB always,
  /// and BLE only if ble_fifo fill is below high-water (75%).
  /// Returns false if skipped for BLE (USB still received it).
  bool inject_host_line(const uint8_t* data, size_t len, bool ble_ok);

  /// Host RX bytes (USB or BLE). Complete lines enqueue to cmd queue.
  void on_host_byte(HostSource src, uint8_t b);

  /// Pop next command byte for radar UART TX. Returns false if empty.
  bool pop_cmd_byte(uint8_t& out);

  RingBuffer& usb_fifo() { return usb_; }
  RingBuffer& ble_fifo() { return ble_; }
  const RingBuffer& ble_fifo() const { return ble_; }

  /// When BLE is full, drop oldest BLE bytes preferentially if they begin a GSIMU line.
  void ble_make_room(size_t need);

 private:
  void feed_line(HostSource src, uint8_t b);
  void enqueue_line(const uint8_t* data, size_t len);

  uint8_t usb_storage_[kUsbFifoSize];
  uint8_t ble_storage_[kBleFifoSize];
  uint8_t cmd_storage_[kCmdQueueSize];
  RingBuffer usb_;
  RingBuffer ble_;
  RingBuffer cmd_;

  uint8_t usb_line_[kLineMax];
  size_t usb_line_len_;
  bool usb_discarding_;
  uint8_t ble_line_[kLineMax];
  size_t ble_line_len_;
  bool ble_discarding_;
};

}  // namespace gotcha
