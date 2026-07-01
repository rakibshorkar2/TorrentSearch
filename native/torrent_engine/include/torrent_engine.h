#ifndef TORRENT_ENGINE_H
#define TORRENT_ENGINE_H

#include <cstdint>
#include <cstddef>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
  const char* info_hash;
  const char* display_name;
  const char** trackers;
  int tracker_count;
} MagnetInfo;

typedef struct {
  const char* key;
  const char* value;
} BencodeEntry;

typedef struct {
  BencodeEntry* entries;
  int entry_count;
  int64_t piece_length;
  int64_t total_length;
  const char** piece_hashes;
  int piece_count;
} TorrentMetadata;

typedef struct {
  int piece_index;
  int block_offset;
  int block_length;
  uint8_t* data;
  int status;
} PieceBlock;

typedef struct {
  uint32_t hash[5];
} Sha1Hash;

// Bencode
int bencode_parse(const char* data, int64_t length, TorrentMetadata* out);
void bencode_free(TorrentMetadata* meta);

// Magnet URI
int magnet_parse(const char* uri, MagnetInfo* out);
void magnet_free(MagnetInfo* info);

// SHA-1
void sha1_init(uint32_t state[5]);
void sha1_update(uint32_t state[5], const uint8_t* data, int64_t len);
void sha1_final(uint32_t state[5], uint8_t digest[20]);
int sha1_verify_piece(const uint8_t* data, int64_t len, const uint8_t* expected_hash);

// Piece Management
typedef void* PieceManagerHandle;
PieceManagerHandle piece_manager_create(int64_t total_size, int64_t piece_size);
void piece_manager_destroy(PieceManagerHandle pm);
int piece_manager_add_block(PieceManagerHandle pm, int piece, int offset, const uint8_t* data, int len);
int piece_manager_is_piece_complete(PieceManagerHandle pm, int piece);
int piece_manager_verify_piece(PieceManagerHandle pm, int piece, const uint8_t* expected_hash);
int piece_manager_get_missing_block(PieceManagerHandle pm, int piece, int* out_offset, int* out_length);
int piece_manager_completed_pieces(PieceManagerHandle pm, int* pieces, int max_count);
int piece_manager_progress(PieceManagerHandle pm, double* out_progress);

// Bandwidth shaping
typedef void* BandwidthManagerHandle;
BandwidthManagerHandle bandwidth_create(int64_t max_down, int64_t max_up);
void bandwidth_destroy(BandwidthManagerHandle bw);
int64_t bandwidth_request_download(BandwidthManagerHandle bw, int64_t bytes);
int64_t bandwidth_request_upload(BandwidthManagerHandle bw, int64_t bytes);
void bandwidth_set_limits(BandwidthManagerHandle bw, int64_t max_down, int64_t max_up);

// Torrent health
double calculate_health(int seeders, int leechers);
const char* health_label(double health);

#ifdef __cplusplus
}
#endif

#endif
