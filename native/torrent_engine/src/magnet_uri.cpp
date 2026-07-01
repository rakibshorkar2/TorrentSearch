#include "magnet_uri.h"
#include <cstring>
#include <cstdlib>
#include <algorithm>

MagnetLink MagnetUriParser::parse(const std::string& uri) {
  MagnetLink link;
  if (!is_valid(uri)) return link;

  std::string query = uri;
  // Remove magnet:? prefix
  auto prefix_pos = query.find("magnet:?");
  if (prefix_pos != std::string::npos) query = query.substr(prefix_pos + 8);

  size_t pos = 0;
  while (pos < query.length()) {
    auto amp = query.find('&', pos);
    std::string param = query.substr(pos, amp == std::string::npos ? std::string::npos : amp - pos);

    auto eq = param.find('=');
    if (eq != std::string::npos) {
      std::string key = param.substr(0, eq);
      std::string value = url_decode(param.substr(eq + 1));

      if (key == "xt") {
        link.info_hash = xt_to_info_hash(value);
      } else if (key == "dn") {
        link.display_name = value;
      } else if (key == "tr") {
        link.trackers.push_back(value);
      } else if (key == "x.ul") {
        link.url_list.push_back(value);
      }
    }

    if (amp == std::string::npos) break;
    pos = amp + 1;
  }

  return link;
}

bool MagnetUriParser::is_valid(const std::string& uri) {
  return uri.find("magnet:?") == 0 && uri.find("xt=urn:btih:") != std::string::npos;
}

std::string MagnetUriParser::url_decode(const std::string& input) {
  std::string result;
  result.reserve(input.length());
  for (size_t i = 0; i < input.length(); i++) {
    if (input[i] == '%' && i + 2 < input.length()) {
      int high = std::stoi(input.substr(i + 1, 2), nullptr, 16);
      result += static_cast<char>(high);
      i += 2;
    } else if (input[i] == '+') {
      result += ' ';
    } else {
      result += input[i];
    }
  }
  return result;
}

std::string MagnetUriParser::xt_to_info_hash(const std::string& xt) {
  // Remove "urn:btih:" prefix
  std::string prefix = "urn:btih:";
  auto pos = xt.find(prefix);
  if (pos == std::string::npos) return "";
  return xt.substr(pos + prefix.length());
}
