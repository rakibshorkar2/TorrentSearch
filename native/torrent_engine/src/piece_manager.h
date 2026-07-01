#ifndef TORRENT_PIECE_MANAGER_H
#define TORRENT_PIECE_MANAGER_H

#include <cstdint>
#include <vector>
#include <mutex>

class PieceManager {
public:
  PieceManager(int64_t total_size, int64_t piece_size);
  ~PieceManager();

  bool add_block(int piece, int offset, const uint8_t* data, int len);
  bool is_piece_complete(int piece) const;
  bool verify_piece(int piece, const uint8_t* expected_hash);
  bool get_missing_block(int piece, int& out_offset, int& out_length) const;
  int completed_pieces(int* pieces, int max_count) const;
  double progress() const;

  int piece_count() const { return piece_count_; }
  int64_t piece_size() const { return piece_size_; }
  int blocks_per_piece() const { return blocks_per_piece_; }

private:
  static const int BLOCK_SIZE = 16384; // 16KB blocks

  struct Piece {
    std::vector<bool> blocks;
    int blocks_received;
    bool verified;
    int size;

    Piece(int num_blocks, int s)
      : blocks(num_blocks, false), blocks_received(0), verified(false), size(s) {}
  };

  int64_t total_size_;
  int64_t piece_size_;
  int piece_count_;
  int blocks_per_piece_;
  std::vector<Piece> pieces_;
  mutable std::mutex mutex_;
};

#endif
