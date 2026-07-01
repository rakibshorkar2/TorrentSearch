#include "sha1.h"
#include <cstring>

Sha1::Sha1() { reset(); }

void Sha1::reset() {
  state_[0] = 0x67452301;
  state_[1] = 0xEFCDAB89;
  state_[2] = 0x98BADCFE;
  state_[3] = 0x10325476;
  state_[4] = 0xC3D2E1F0;
  count_ = 0;
  buffer_len_ = 0;
}

uint32_t Sha1::rotl(uint32_t value, int bits) {
  return (value << bits) | (value >> (32 - bits));
}

void Sha1::transform(const uint8_t block[64]) {
  uint32_t w[80];
  for (int i = 0; i < 16; i++) {
    w[i] = (block[i*4] << 24) | (block[i*4+1] << 16) | (block[i*4+2] << 8) | block[i*4+3];
  }
  for (int i = 16; i < 80; i++) {
    w[i] = rotl(w[i-3] ^ w[i-8] ^ w[i-14] ^ w[i-16], 1);
  }

  uint32_t a = state_[0], b = state_[1], c = state_[2], d = state_[3], e = state_[4];

  for (int i = 0; i < 80; i++) {
    uint32_t f, k;
    if (i < 20)      { f = (b & c) | (~b & d); k = 0x5A827999; }
    else if (i < 40) { f = b ^ c ^ d;          k = 0x6ED9EBA1; }
    else if (i < 60) { f = (b & c) | (b & d) | (c & d); k = 0x8F1BBCDC; }
    else             { f = b ^ c ^ d;          k = 0xCA62C1D6; }

    uint32_t temp = rotl(a, 5) + f + e + k + w[i];
    e = d; d = c; c = rotl(b, 30); b = a; a = temp;
  }

  state_[0] += a; state_[1] += b; state_[2] += c; state_[3] += d; state_[4] += e;
}

void Sha1::update(const uint8_t* data, int64_t len) {
  count_ += len * 8;
  int64_t idx = buffer_len_;
  buffer_len_ = (buffer_len_ + len) & 63;

  if (idx + len >= 64) {
    memcpy(buffer_ + idx, data, 64 - idx);
    transform(buffer_);
    int64_t i = 64 - idx;
    for (; i + 63 < len; i += 64) transform(data + i);
    idx = 0;
    memcpy(buffer_, data + i, len - i);
  } else {
    memcpy(buffer_ + idx, data, len);
  }
}

void Sha1::final(uint8_t digest[20]) {
  uint64_t bits = count_;
  update(reinterpret_cast<const uint8_t*>("\x80"), 1);
  while (buffer_len_ != 56) update(reinterpret_cast<const uint8_t*>("\x00"), 1);

  uint8_t count_bytes[8];
  for (int i = 0; i < 8; i++) count_bytes[i] = static_cast<uint8_t>((bits >> (56 - i * 8)) & 0xFF);
  update(count_bytes, 8);

  for (int i = 0; i < 5; i++) {
    digest[i*4]   = (state_[i] >> 24) & 0xFF;
    digest[i*4+1] = (state_[i] >> 16) & 0xFF;
    digest[i*4+2] = (state_[i] >> 8) & 0xFF;
    digest[i*4+3] = state_[i] & 0xFF;
  }
}

bool Sha1::verify(const uint8_t* data, int64_t len, const uint8_t* expected) {
  Sha1 sha;
  sha.update(data, len);
  uint8_t digest[20];
  sha.final(digest);
  return memcmp(digest, expected, 20) == 0;
}
