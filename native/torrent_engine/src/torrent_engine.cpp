#include "../include/torrent_engine.h"
#include "bencode.h"
#include "magnet_uri.h"
#include "sha1.h"
#include "piece_manager.h"
#include <cstring>
#include <cstdlib>
#include <cmath>
#include <chrono>

// MARK: - Bencode C API

int bencode_parse(const char* data, int64_t length, TorrentMetadata* out) {
  if (!data || !out) return -1;
  try {
    auto val = BencodeParser::parse(reinterpret_cast<const uint8_t*>(data), length);
    if (val.type() != BencodeValue::DICT) return -1;

    // Parse info dict
    auto* info = val.get("info");
    if (!info || info->type() != BencodeValue::DICT) return -1;

    // piece length and pieces are inside the info dict, not at root level
    auto* piece_length = info->get("piece length");
    if (piece_length) out->piece_length = piece_length->int_val();

    auto* pieces = info->get("pieces");
    if (pieces && pieces->type() == BencodeValue::STRING) {
      out->piece_count = static_cast<int>(pieces->str_val().length() / 20);
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

SHA1Handle sha1_create() {
  return reinterpret_cast<SHA1Handle>(new Sha1());
}

void sha1_destroy(SHA1Handle ctx) {
  delete reinterpret_cast<Sha1*>(ctx);
}

void sha1_reset(SHA1Handle ctx) {
  reinterpret_cast<Sha1*>(ctx)->reset();
}

void sha1_update(SHA1Handle ctx, const uint8_t* data, int64_t len) {
  reinterpret_cast<Sha1*>(ctx)->update(data, len);
}

void sha1_final(SHA1Handle ctx, uint8_t digest[20]) {
  reinterpret_cast<Sha1*>(ctx)->final(digest);
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
  int offset = 0, length = 0;
  auto* mgr = reinterpret_cast<PieceManager*>(pm);
  bool result = mgr->get_missing_block(piece, offset, length);
  if (out_offset) *out_offset = offset;
  if (out_length) *out_length = length;
  return result ? 1 : 0;
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
  std::chrono::steady_clock::time_point last_tick;

  BandwidthManager(int64_t md, int64_t mu)
    : max_down(md), max_up(mu), down_used(0), up_used(0), last_tick(std::chrono::steady_clock::now()) {}
};

BandwidthManagerHandle bandwidth_create(int64_t max_down, int64_t max_up) {
  return reinterpret_cast<BandwidthManagerHandle>(new BandwidthManager(max_down, max_up));
}

void bandwidth_destroy(BandwidthManagerHandle bw) {
  delete reinterpret_cast<BandwidthManager*>(bw);
}

static void bandwidth_tick(BandwidthManager* bwm) {
  auto now = std::chrono::steady_clock::now();
  auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(now - bwm->last_tick).count();
  if (elapsed >= 1000) {
    bwm->down_used = 0;
    bwm->up_used = 0;
    bwm->last_tick = now;
  }
}

int64_t bandwidth_request_download(BandwidthManagerHandle bw, int64_t bytes) {
  auto* bwm = reinterpret_cast<BandwidthManager*>(bw);
  bandwidth_tick(bwm);
  if (bwm->max_down <= 0) return bytes;
  int64_t allowed = bwm->max_down - bwm->down_used;
  if (allowed <= 0) return 0;
  int64_t granted = (bytes < allowed) ? bytes : allowed;
  bwm->down_used += granted;
  return granted;
}

int64_t bandwidth_request_upload(BandwidthManagerHandle bw, int64_t bytes) {
  auto* bwm = reinterpret_cast<BandwidthManager*>(bw);
  bandwidth_tick(bwm);
  if (bwm->max_up <= 0) return bytes;
  int64_t allowed = bwm->max_up - bwm->up_used;
  if (allowed <= 0) return 0;
  int64_t granted = (bytes < allowed) ? bytes : allowed;
  bwm->up_used += granted;
  return granted;
}

void bandwidth_set_limits(BandwidthManagerHandle bw, int64_t max_down, int64_t max_up) {
  auto* bwm = reinterpret_cast<BandwidthManager*>(bw);
  bandwidth_tick(bwm);
  bwm->max_down = max_down;
  bwm->max_up = max_up;
}

void bandwidth_tick_time(BandwidthManagerHandle bw, int64_t now_ms) {
  (void)now_ms;
  auto* bwm = reinterpret_cast<BandwidthManager*>(bw);
  bandwidth_tick(bwm);
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
