#include "bridge.hpp"

#include <cstring>

namespace gotcha {

RingBuffer::RingBuffer(uint8_t* storage, size_t capacity)
    : storage_(storage), capacity_(capacity), head_(0), tail_(0), count_(0) {}

size_t RingBuffer::count() const { return count_; }

bool RingBuffer::push(uint8_t b) {
  if (full()) {
    return false;
  }
  storage_[head_] = b;
  head_ = (head_ + 1) % capacity_;
  ++count_;
  return true;
}

size_t RingBuffer::push(const uint8_t* data, size_t len) {
  size_t n = 0;
  while (n < len && push(data[n])) {
    ++n;
  }
  return n;
}

bool RingBuffer::drop_oldest() {
  uint8_t unused;
  return pop(unused);
}

bool RingBuffer::pop(uint8_t& out) {
  if (empty()) {
    return false;
  }
  out = storage_[tail_];
  tail_ = (tail_ + 1) % capacity_;
  --count_;
  return true;
}

size_t RingBuffer::pop(uint8_t* out, size_t max_len) {
  size_t n = 0;
  while (n < max_len && pop(out[n])) {
    ++n;
  }
  return n;
}

size_t RingBuffer::peek(uint8_t* out, size_t max_len) const {
  size_t n = count_ < max_len ? count_ : max_len;
  for (size_t i = 0; i < n; ++i) {
    out[i] = storage_[(tail_ + i) % capacity_];
  }
  return n;
}

size_t RingBuffer::discard(size_t n) {
  size_t dropped = 0;
  uint8_t unused;
  while (dropped < n && pop(unused)) {
    ++dropped;
  }
  return dropped;
}

void RingBuffer::clear() {
  head_ = tail_ = count_ = 0;
}

bool RingBuffer::starts_with_gsimu() const {
  static const char kPrefix[] = "$GSIMU";
  if (count_ < sizeof(kPrefix) - 1) {
    return false;
  }
  for (size_t i = 0; i < sizeof(kPrefix) - 1; ++i) {
    size_t idx = (tail_ + i) % capacity_;
    if (storage_[idx] != static_cast<uint8_t>(kPrefix[i])) {
      return false;
    }
  }
  return true;
}

Bridge::Bridge()
    : usb_(usb_storage_, kUsbFifoSize),
      ble_(ble_storage_, kBleFifoSize),
      cmd_(cmd_storage_, kCmdQueueSize),
      usb_line_len_(0),
      usb_discarding_(false),
      ble_line_len_(0),
      ble_discarding_(false) {}

void Bridge::on_radar_byte(uint8_t b) {
  (void)usb_.push(b);
  if (!ble_.push(b)) {
    ble_make_room(1);
    (void)ble_.push(b);
  }
}

bool Bridge::inject_host_line(const uint8_t* data, size_t len, bool ble_ok) {
  for (size_t i = 0; i < len; ++i) {
    (void)usb_.push(data[i]);
  }
  if (!ble_ok) {
    return false;
  }
  // High water: skip BLE inject if more than 75% full.
  if (ble_.count() * 4 > ble_.capacity() * 3) {
    return false;
  }
  for (size_t i = 0; i < len; ++i) {
    if (!ble_.push(data[i])) {
      ble_make_room(1);
      (void)ble_.push(data[i]);
    }
  }
  return true;
}

void Bridge::on_host_byte(HostSource src, uint8_t b) { feed_line(src, b); }

bool Bridge::pop_cmd_byte(uint8_t& out) { return cmd_.pop(out); }

void Bridge::ble_make_room(size_t need) {
  while (ble_.free_space() < need && !ble_.empty()) {
    if (ble_.starts_with_gsimu()) {
      // Drop until end of line or buffer empty.
      uint8_t b;
      while (ble_.pop(b)) {
        if (b == '\n') {
          break;
        }
      }
    } else {
      (void)ble_.drop_oldest();
    }
  }
}

void Bridge::feed_line(HostSource src, uint8_t b) {
  uint8_t* line = (src == HostSource::Usb) ? usb_line_ : ble_line_;
  size_t& len = (src == HostSource::Usb) ? usb_line_len_ : ble_line_len_;
  bool& discarding = (src == HostSource::Usb) ? usb_discarding_ : ble_discarding_;

  if (b == '\n') {
    if (!discarding && len > 0) {
      // USB is drained before BLE each loop, so simultaneous completes keep order.
      enqueue_line(line, len);
    }
    len = 0;
    discarding = false;
    return;
  }
  if (b == '\r') {
    return;
  }
  if (discarding) {
    return;
  }
  if (len >= kLineMax) {
    // Oversize incomplete line: drop rest until newline.
    len = 0;
    discarding = true;
    return;
  }
  line[len++] = b;
}

void Bridge::enqueue_line(const uint8_t* data, size_t len) {
  // USB-first arbitration: if USB already has a pending complete command in
  // the queue, BLE still appends after it — callers drain host sources USB then
  // BLE each loop, so simultaneous completes enqueue USB first.
  for (size_t i = 0; i < len; ++i) {
    if (!cmd_.push(data[i])) {
      return;
    }
  }
  (void)cmd_.push(static_cast<uint8_t>('\r'));
  (void)cmd_.push(static_cast<uint8_t>('\n'));
}

}  // namespace gotcha
