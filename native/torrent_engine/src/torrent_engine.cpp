#include "../include/torrent_engine.h"
#include "bencode.h"
#include "magnet_uri.h"
#include "sha1.h"
#include "piece_manager.h"
#include <cstring>
#include <cstdlib>
#include <cmath>

// MARK: - Bencode C API

int bencode_parse(const char* data, int64_t length, TorrentMetadata* out) {
  if (!data || !out) return -1;
  try {
    auto val = BencodeParser::parse(reinterpret_cast<const uint8_t*>(data), length);
    if (val.type() != BencodeValue::DICT) return -1;

    // Parse info dict
    auto* info = val.get("info");
    if (!info || info->type() != BencodeValue::DICT) return -1;

    auto* piece_length = val.get("piece length");
    if (piece_length) out->piece_length = piece_length->int_val();

    auto* pieces = val.get("pieces");
    if (pieces && pieces->type() == BencodeValue::STRING) {
      out->piece_count = pieces->str_val().length() / 20;
      out->piece_hashes = static_cast<const char**>(calloc(out->piece_count, sizeof(char*)));
      for (int i = 0; i < out->piece_count; i++) {
        auto* hash = static_cast<char*>(malloc(20));
        memcpy(hash, pieces->str_val().data() + i * 20, 20);
        out->piece_hashes[i] = hash;
      }
    }

    // Parse length (single file) or files (multi-file)
    auto* length = info->get("length");
    if (length) {
      out->total_length = length->int_val();
    }

    return 0;
  } catch (...) {
    return -1;
  }
}

void bencode_free(TorrentMetadata* meta) {
  if (!meta) return;
  if (meta->piece_hashes) {
    for (int i = 0; i < meta->piece_count; i++) {
      free(const_cast<char*>(meta->piece_hashes[i]));
    }
    free(meta->piece_hashes);
  }
  if (meta->entries) free(meta->entries);
}

// MARK: - Magnet URI C API

int magnet_parse(const char* uri, MagnetInfo* out) {
  if (!uri || !out) return -1;
  try {
    auto link = MagnetUriParser::parse(std::string(uri));
    if (link.info_hash.empty()) return -1;

    out->info_hash = strdup(link.info_hash.c_str());
    out->display_name = link.display_name.empty() ? nullptr : strdup(link.display_name.c_str());
    out->tracker_count = static_cast<int>(link.trackers.size());
    if (!link.trackers.empty()) {
      out->trackers = static_cast<const char**>(calloc(link.trackers.size(), sizeof(char*)));
      for (size_t i = 0; i < link.trackers.size(); i++) {
        out->trackers[i] = strdup(link.trackers[i].c_str());
      }
    } else {
      out->trackers = nullptr;
    }
    return 0;
  } catch (...) {
    return -1;
  }
}

void magnet_free(MagnetInfo* info) {
  if (!info) return;
  free(const_cast<char*>(info->info_hash));
  free(const_cast<char*>(info->display_name));
  if (info->trackers) {
    for (int i = 0; i < info->tracker_count; i++) {
      free(const_cast<char*>(info->trackers[i]));
    }
    free(info->trackers);
  }
}

// MARK: - SHA-1 C API

void sha1_init(uint32_t state[5]) {
  state[0] = 0x67452301;
  state[1] = 0xEFCDAB89;
  state[2] = 0x98BADCFE;
  state[3] = 0x10325476;
  state[4] = 0xC3D2E1F0;
}

void sha1_update(uint32_t state[5], const uint8_t* data, int64_t len) {
  // Simple wrapper - real implementation would accumulate
  Sha1 sha;
  sha.update(data, len);
}

void sha1_final(uint32_t state[5], uint8_t digest[20]) {
  // Simplified - real implementation would finalize
}

int sha1_verify_piece(const uint8_t* data, int64_t len, const uint8_t* expected_hash) {
  return Sha1::verify(data, len, expected_hash) ? 1 : 0;
}

// MARK: - Piece Management C API

PieceManagerHandle piece_manager_create(int64_t total_size, int64_t piece_size) {
  auto* pm = new PieceManager(total_size, piece_size);
  return reinterpret_cast<PieceManagerHandle>(pm);
}

void piece_manager_destroy(PieceManagerHandle pm) {
  delete reinterpret_cast<PieceManager*>(pm);
}

int piece_manager_add_block(PieceManagerHandle pm, int piece, int offset, const uint8_t* data, int len) {
  return reinterpret_cast<PieceManager*>(pm)->add_block(piece, offset, data, len) ? 1 : 0;
}

int piece_manager_is_piece_complete(PieceManagerHandle pm, int piece) {
  return reinterpret_cast<PieceManager*>(pm)->is_piece_complete(piece) ? 1 : 0;
}

int piece_manager_verify_piece(PieceManagerHandle pm, int piece, const uint8_t* expected_hash) {
  return reinterpret_cast<PieceManager*>(pm)->verify_piece(piece, expected_hash) ? 1 : 0;
}

int piece_manager_get_missing_block(PieceManagerHandle pm, int piece, int* out_offset, int* out_length) {
  return reinterpret_cast<PieceManager*>(pm)->get_missing_block(piece, *out_offset, *out_length) ? 1 : 0;
}

int piece_manager_completed_pieces(PieceManagerHandle pm, int* pieces, int max_count) {
  return reinterpret_cast<PieceManager*>(pm)->completed_pieces(pieces, max_count);
}

int piece_manager_progress(PieceManagerHandle pm, double* out_progress) {
  *out_progress = reinterpret_cast<PieceManager*>(pm)->progress();
  return 0;
}

// MARK: - Bandwidth Management

struct BandwidthManager {
  int64_t max_down;
  int64_t max_up;
  int64_t down_used;
  int64_t up_used;
  int64_t last_tick;

  BandwidthManager(int64_t md, int64_t mu)
    : max_down(md), max_up(mu), down_used(0), up_used(0), last_tick(0) {}
};

BandwidthManagerHandle bandwidth_create(int64_t max_down, int64_t max_up) {
  return reinterpret_cast<BandwidthManagerHandle>(new BandwidthManager(max_down, max_up));
}

void bandwidth_destroy(BandwidthManagerHandle bw) {
  delete reinterpret_cast<BandwidthManager*>(bw);
}

int64_t bandwidth_request_download(BandwidthManagerHandle bw, int64_t bytes) {
  auto* bwm = reinterpret_cast<BandwidthManager*>(bw);
  if (bwm->max_down <= 0) return bytes;
  int64_t allowed = bwm->max_down - bwm->down_used;
  if (allowed <= 0) return 0;
  int64_t granted = (bytes < allowed) ? bytes : allowed;
  bwm->down_used += granted;
  return granted;
}

int64_t bandwidth_request_upload(BandwidthManagerHandle bw, int64_t bytes) {
  auto* bwm = reinterpret_cast<BandwidthManager*>(bw);
  if (bwm->max_up <= 0) return bytes;
  int64_t allowed = bwm->max_up - bwm->up_used;
  if (allowed <= 0) return 0;
  int64_t granted = (bytes < allowed) ? bytes : allowed;
  bwm->up_used += granted;
  return granted;
}

void bandwidth_set_limits(BandwidthManagerHandle bw, int64_t max_down, int64_t max_up) {
  auto* bwm = reinterpret_cast<BandwidthManager*>(bw);
  bwm->max_down = max_down;
  bwm->max_up = max_up;
}

// MARK: - Health

double calculate_health(int seeders, int leechers) {
  if (seeders <= 0) return 0.0;
  if (leechers <= 0) return 1.0;
  double ratio = static_cast<double>(seeders) / leechers;
  if (ratio >= 5.0) return 1.0;
  if (ratio >= 2.0) return 0.8;
  if (ratio >= 1.0) return 0.5;
  return 0.2;
}

const char* health_label(double health) {
  if (health >= 0.9) return "Excellent";
  if (health >= 0.7) return "Good";
  if (health >= 0.4) return "OK";
  if (health >= 0.1) return "Poor";
  return "Dead";
}
