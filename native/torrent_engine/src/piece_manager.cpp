#include "piece_manager.h"
#include "sha1.h"
#include <algorithm>
#include <cstring>

PieceManager::PieceManager(int64_t total_size, int64_t piece_size)
  : total_size_(total_size), piece_size_(piece_size) {

  piece_count_ = (total_size_ + piece_size_ - 1) / piece_size_;
  blocks_per_piece_ = (piece_size_ + BLOCK_SIZE - 1) / BLOCK_SIZE;

  pieces_.reserve(piece_count_);
  for (int i = 0; i < piece_count_; i++) {
    int64_t remaining = total_size_ - static_cast<int64_t>(i) * piece_size_;
    int psize = static_cast<int>((std::min)(static_cast<int64_t>(piece_size_), remaining));
    int num_blocks = (psize + BLOCK_SIZE - 1) / BLOCK_SIZE;
    pieces_.emplace_back(num_blocks, psize);
  }
}

PieceManager::~PieceManager() = default;

bool PieceManager::add_block(int piece, int offset, const uint8_t* data, int len) {
  std::lock_guard<std::mutex> lock(mutex_);
  if (piece < 0 || piece >= piece_count_) return false;

  auto& p = pieces_[piece];
  if (p.verified) return true;

  int block_index = offset / BLOCK_SIZE;
  if (block_index < 0 || block_index >= static_cast<int>(p.blocks.size())) return false;
  if (p.blocks[block_index]) return true;

  p.blocks[block_index] = true;
  p.blocks_received++;
  return true;
}

bool PieceManager::is_piece_complete(int piece) const {
  std::lock_guard<std::mutex> lock(mutex_);
  if (piece < 0 || piece >= piece_count_) return false;
  const auto& p = pieces_[piece];
  return p.blocks_received >= static_cast<int>(p.blocks.size());
}

bool PieceManager::verify_piece(int piece, const uint8_t* expected_hash) {
  std::lock_guard<std::mutex> lock(mutex_);
  if (piece < 0 || piece >= piece_count_) return false;

  auto& p = pieces_[piece];
  if (p.verified) return true;
  if (p.blocks_received < static_cast<int>(p.blocks.size())) return false;

  // In a real implementation, we would reconstruct the piece data and hash it
  // For now, we trust the block count
  p.verified = true;
  return true;
}

bool PieceManager::get_missing_block(int piece, int& out_offset, int& out_length) const {
  std::lock_guard<std::mutex> lock(mutex_);
  if (piece < 0 || piece >= piece_count_) return false;

  const auto& p = pieces_[piece];
  for (size_t i = 0; i < p.blocks.size(); i++) {
    if (!p.blocks[i]) {
      out_offset = static_cast<int>(i * BLOCK_SIZE);
      out_length = (std::min)(BLOCK_SIZE, p.size - out_offset);
      return true;
    }
  }
  return false;
}

int PieceManager::completed_pieces(int* pieces, int max_count) const {
  std::lock_guard<std::mutex> lock(mutex_);
  int count = 0;
  for (int i = 0; i < piece_count_ && count < max_count; i++) {
    if (pieces_[i].verified) {
      pieces[count++] = i;
    }
  }
  return count;
}

double PieceManager::progress() const {
  std::lock_guard<std::mutex> lock(mutex_);
  if (piece_count_ == 0) return 0.0;
  int total = 0;
  for (const auto& p : pieces_) {
    total += p.blocks_received;
  }
  int total_blocks = piece_count_ * blocks_per_piece_;
  return total_blocks > 0 ? static_cast<double>(total) / total_blocks : 0.0;
}
