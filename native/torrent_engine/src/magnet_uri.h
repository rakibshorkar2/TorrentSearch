#ifndef TORRENT_MAGNET_URI_H
#define TORRENT_MAGNET_URI_H

#include <string>
#include <vector>

struct MagnetLink {
  std::string info_hash;
  std::string display_name;
  std::vector<std::string> trackers;
  std::vector<std::string> url_list;
};

class MagnetUriParser {
public:
  static MagnetLink parse(const std::string& uri);
  static bool is_valid(const std::string& uri);

private:
  static std::string url_decode(const std::string& input);
  static std::string xt_to_info_hash(const std::string& xt);
};

#endif
