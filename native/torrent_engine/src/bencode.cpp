#include "bencode.h"
#include <cstdlib>
#include <cstring>

const BencodeValue* BencodeValue::get(const std::string& key) const {
  if (type_ != DICT) return nullptr;
  auto it = dict_val_.find(key);
  return it != dict_val_.end() ? &it->second : nullptr;
}

BencodeValue BencodeParser::parse(const uint8_t* data, int64_t len) {
  BencodeParser parser(data, len);
  return parser.parse_value();
}

BencodeValue BencodeParser::parse(const std::string& data) {
  return parse(reinterpret_cast<const uint8_t*>(data.data()), data.length());
}

char BencodeParser::peek() {
  return pos_ < len_ ? static_cast<char>(data_[pos_]) : '\0';
}

char BencodeParser::next() {
  return pos_ < len_ ? static_cast<char>(data_[pos_++]) : '\0';
}

bool BencodeParser::has_more() {
  return pos_ < len_;
}

void BencodeParser::skip_whitespace() {
  while (pos_ < len_ && (data_[pos_] == ' ' || data_[pos_] == '\t' || data_[pos_] == '\n' || data_[pos_] == '\r')) pos_++;
}

int64_t BencodeParser::parse_int() {
  // consume 'i'
  next();
  int64_t val = 0;
  bool neg = false;
  if (peek() == '-') { neg = true; next(); }
  while (pos_ < len_ && peek() >= '0' && peek() <= '9') {
    val = val * 10 + (next() - '0');
  }
  // consume 'e'
  if (peek() == 'e') next();
  return neg ? -val : val;
}

std::string BencodeParser::parse_string() {
  int64_t len = 0;
  while (pos_ < len_ && peek() >= '0' && peek() <= '9') {
    len = len * 10 + (next() - '0');
  }
  // consume ':'
  if (peek() == ':') next();
  std::string result(reinterpret_cast<const char*>(data_ + pos_), len);
  pos_ += len;
  return result;
}

BencodeValue::List BencodeParser::parse_list() {
  next(); // consume 'l'
  BencodeValue::List list;
  while (has_more() && peek() != 'e') {
    list.push_back(parse_value());
  }
  if (peek() == 'e') next();
  return list;
}

BencodeValue::Dict BencodeParser::parse_dict() {
  next(); // consume 'd'
  BencodeValue::Dict dict;
  while (has_more() && peek() != 'e') {
    std::string key = parse_string();
    dict[key] = parse_value();
  }
  if (peek() == 'e') next();
  return dict;
}

BencodeValue BencodeParser::parse_value() {
  skip_whitespace();
  char c = peek();
  switch (c) {
    case 'i': return BencodeValue(parse_int());
    case 'l': return BencodeValue(parse_list());
    case 'd': return BencodeValue(parse_dict());
    default:
      if ((c >= '0' && c <= '9') || c == '-') {
        return BencodeValue(parse_string());
      }
      return BencodeValue();
  }
}
