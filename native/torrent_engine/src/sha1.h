#ifndef TORRENT_SHA1_H
#define TORRENT_SHA1_H

#include <cstdint>
#include <cstddef>

class Sha1 {
public:
  Sha1();
  void update(const uint8_t* data, int64_t len);
  void final(uint8_t digest[20]);
  void reset();

  static bool verify(const uint8_t* data, int64_t len, const uint8_t* expected);

private:
  uint32_t state_[5];
  uint64_t count_;
  uint8_t buffer_[64];
  int buffer_len_;

  void transform(const uint8_t block[64]);
  static uint32_t rotl(uint32_t value, int bits);
};

#endif
