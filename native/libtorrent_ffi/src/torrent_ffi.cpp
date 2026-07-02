#include "../include/torrent_ffi.h"
#include <libtorrent/session.hpp>
#include <libtorrent/add_torrent_params.hpp>
#include <libtorrent/torrent_handle.hpp>
#include <libtorrent/alert_types.hpp>
#include <libtorrent/bencode.hpp>
#include <libtorrent/magnet_uri.hpp>
#include <libtorrent/announce_entry.hpp>
#include <cstring>
#include <string>
#include <vector>
#include <map>
#include <mutex>

struct TorrentSession {
  lt::session session;
  std::map<int, lt::torrent_handle> handles;
  int next_id = 1;
  std::mutex mutex;
  std::string save_path;

  TorrentSession(const char* path) : session(), save_path(path) {
    lt::settings_pack sp;
    sp.set_int(lt::settings_pack::alert_mask, lt::alert::status_notification |
      lt::alert::error_notification | lt::alert::progress_notification);
    session.apply_settings(sp);
  }
};

static int to_c_state(lt::torrent_status::state_t s) {
  switch (s) {
    case lt::torrent_status::queued_for_checking: return 0;
    case lt::torrent_status::checking_files: return 1;
    case lt::torrent_status::downloading_metadata: return 2;
    case lt::torrent_status::downloading: return 3;
    case lt::torrent_status::finished: return 4;
    case lt::torrent_status::seeding: return 5;
    case lt::torrent_status::allocating: return 6;
    case lt::torrent_status::checking_resume_data: return 7;
    default: return -1;
  }
}

static void fill_status(const lt::torrent_status& ts, TorrentStatusC* out) {
  out->progress = ts.progress;
  out->download_rate = static_cast<int64_t>(ts.download_rate);
  out->upload_rate = static_cast<int64_t>(ts.upload_rate);
  out->total_download = static_cast<int64_t>(ts.total_download);
  out->total_upload = static_cast<int64_t>(ts.total_upload);
  out->total_size = static_cast<int64_t>(ts.total_wanted);
  out->seeders = static_cast<int>(ts.num_seeds);
  out->leechers = static_cast<int>(ts.num_peers - ts.num_seeds);
  out->peers = static_cast<int>(ts.num_peers);
  out->state = to_c_state(ts.state);
  out->error[0] = '\0';
}

TorrentSessionHandle torrent_session_create(const char* save_path) {
  auto* ts = new TorrentSession(save_path);
  return reinterpret_cast<TorrentSessionHandle>(ts);
}

void torrent_session_destroy(TorrentSessionHandle session) {
  delete reinterpret_cast<TorrentSession*>(session);
}

int torrent_session_add_magnet(TorrentSessionHandle session, const char* magnet_uri, const char* save_path) {
  auto* ts = reinterpret_cast<TorrentSession*>(session);
  std::lock_guard<std::mutex> lock(ts->mutex);

  lt::add_torrent_params p;
  lt::error_code ec;
  lt::parse_magnet_uri(magnet_uri, p, ec);
  if (ec) return -1;

  p.save_path = save_path ? save_path : ts->save_path;
  p.storage_mode = lt::storage_mode_t::storage_mode_sparse;

  lt::torrent_handle h = ts->session.add_torrent(p, ec);
  if (ec) return -1;

  int id = ts->next_id++;
  ts->handles[id] = h;
  return id;
}

int torrent_session_add_torrent_file(TorrentSessionHandle session, const char* file_path, const char* save_path) {
  auto* ts = reinterpret_cast<TorrentSession*>(session);
  std::lock_guard<std::mutex> lock(ts->mutex);

  lt::add_torrent_params p;
  lt::error_code ec;
  p.ti = std::make_shared<lt::torrent_info>(file_path, ec);
  if (ec) return -1;

  p.save_path = save_path ? save_path : ts->save_path;
  p.storage_mode = lt::storage_mode_t::storage_mode_sparse;

  lt::torrent_handle h = ts->session.add_torrent(p, ec);
  if (ec) return -1;

  int id = ts->next_id++;
  ts->handles[id] = h;
  return id;
}

void torrent_session_remove(TorrentSessionHandle session, int handle_id) {
  auto* ts = reinterpret_cast<TorrentSession*>(session);
  std::lock_guard<std::mutex> lock(ts->mutex);
  auto it = ts->handles.find(handle_id);
  if (it != ts->handles.end()) {
    ts->session.remove_torrent(it->second);
    ts->handles.erase(it);
  }
}

void torrent_session_pause(TorrentSessionHandle session, int handle_id) {
  auto* ts = reinterpret_cast<TorrentSession*>(session);
  std::lock_guard<std::mutex> lock(ts->mutex);
  auto it = ts->handles.find(handle_id);
  if (it != ts->handles.end()) it->second.pause();
}

void torrent_session_resume(TorrentSessionHandle session, int handle_id) {
  auto* ts = reinterpret_cast<TorrentSession*>(session);
  std::lock_guard<std::mutex> lock(ts->mutex);
  auto it = ts->handles.find(handle_id);
  if (it != ts->handles.end()) it->second.resume();
}

int torrent_session_pop_alerts(TorrentSessionHandle session, TorrentAlertC* out_alerts, int max_alerts) {
  auto* ts = reinterpret_cast<TorrentSession*>(session);
  std::lock_guard<std::mutex> lock(ts->mutex);

  std::vector<lt::alert*> alerts;
  ts->session.pop_alerts(&alerts);

  int count = 0;
  for (auto* a : alerts) {
    if (count >= max_alerts) break;

    auto* sa = lt::alert_cast<lt::state_update_alert>(a);
    if (sa && !sa->status.empty()) {
      const auto& st = sa->status[0];
      // Find handle_id for this torrent
      int hid = -1;
      for (const auto& [id, h] : ts->handles) {
        if (h == sa->handle) { hid = id; break; }
      }
      if (hid >= 0) {
        out_alerts[count].handle_id = hid;
        fill_status(st, &out_alerts[count].status);
        std::strncpy(out_alerts[count].name, st.name.c_str(), 255);
        count++;
      }
    }

    auto* fa = lt::alert_cast<lt::torrent_finished_alert>(a);
    if (fa) {
      int hid = -1;
      for (const auto& [id, h] : ts->handles) {
        if (h == fa->handle) { hid = id; break; }
      }
      if (hid >= 0 && count < max_alerts) {
        out_alerts[count].handle_id = hid;
        out_alerts[count].status.progress = 1.0;
        out_alerts[count].status.state = 4;
        std::strncpy(out_alerts[count].name, fa->handle.status().name.c_str(), 255);
        count++;
      }
    }

    auto* ea = lt::alert_cast<lt::torrent_error_alert>(a);
    if (ea) {
      int hid = -1;
      for (const auto& [id, h] : ts->handles) {
        if (h == ea->handle) { hid = id; break; }
      }
      if (hid >= 0 && count < max_alerts) {
        out_alerts[count].handle_id = hid;
        out_alerts[count].status.state = -1;
        std::strncpy(out_alerts[count].status.error, ea->message().c_str(), 255);
        std::strncpy(out_alerts[count].name, ea->handle.status().name.c_str(), 255);
        count++;
      }
    }
  }

  return count;
}

int torrent_session_get_status(TorrentSessionHandle session, int handle_id, TorrentStatusC* out_status) {
  auto* ts = reinterpret_cast<TorrentSession*>(session);
  std::lock_guard<std::mutex> lock(ts->mutex);

  auto it = ts->handles.find(handle_id);
  if (it == ts->handles.end()) return -1;

  auto st = it->second.status();
  fill_status(st, out_status);
  return 0;
}

int torrent_session_get_all_statuses(TorrentSessionHandle session, TorrentStatusC* out_statuses, int max_count) {
  auto* ts = reinterpret_cast<TorrentSession*>(session);
  std::lock_guard<std::mutex> lock(ts->mutex);

  int count = 0;
  for (const auto& [id, h] : ts->handles) {
    if (count >= max_count) break;
    auto st = h.status();
    fill_status(st, &out_statuses[count]);
    count++;
  }
  return count;
}

void torrent_session_set_download_limit(TorrentSessionHandle session, int handle_id, int64_t limit) {
  auto* ts = reinterpret_cast<TorrentSession*>(session);
  std::lock_guard<std::mutex> lock(ts->mutex);
  auto it = ts->handles.find(handle_id);
  if (it != ts->handles.end()) it->second.set_download_limit(static_cast<int>(limit));
}

void torrent_session_set_upload_limit(TorrentSessionHandle session, int handle_id, int64_t limit) {
  auto* ts = reinterpret_cast<TorrentSession*>(session);
  std::lock_guard<std::mutex> lock(ts->mutex);
  auto it = ts->handles.find(handle_id);
  if (it != ts->handles.end()) it->second.set_upload_limit(static_cast<int>(limit));
}
