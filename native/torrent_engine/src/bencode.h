#ifndef TORRENT_BENCODE_H
#define TORRENT_BENCODE_H

#include <cstdint>
#include <string>
#include <vector>
#include <map>
#include <variant>

class BencodeValue {
public:
  using Dict = std::map<std::string, BencodeValue>;
  using List = std::vector<BencodeValue>;

  enum Type { INTEGER, STRING, LIST, DICT };

  BencodeValue() : type_(INTEGER), int_val_(0) {}
  explicit BencodeValue(int64_t v) : type_(INTEGER), int_val_(v) {}
  explicit BencodeValue(const std::string& s) : type_(STRING), str_val_(s) {}
  explicit BencodeValue(const List& l) : type_(LIST), list_val_(l) {}
  explicit BencodeValue(const Dict& d) : type_(DICT), dict_val_(d) {}

  Type type() const { return type_; }
  int64_t int_val() const { return int_val_; }
  const std::string& str_val() const { return str_val_; }
  const List& list_val() const { return list_val_; }
  const Dict& dict_val() const { return dict_val_; }

  const BencodeValue* get(const std::string& key) const;

private:
  Type type_;
  int64_t int_val_;
  std::string str_val_;
  List list_val_;
  Dict dict_val_;
};

class BencodeParser {
public:
  static BencodeValue parse(const uint8_t* data, int64_t len);
  static BencodeValue parse(const std::string& data);

private:
  const uint8_t* data_;
  int64_t len_;
  int64_t pos_;

  BencodeParser(const uint8_t* d, int64_t l) : data_(d), len_(l), pos_(0) {}
  BencodeValue parse_value();
  int64_t parse_int();
  std::string parse_string();
  BencodeValue::List parse_list();
  BencodeValue::Dict parse_dict();
  void skip_whitespace();
  char peek();
  char next();
  bool has_more();
};

#endif
