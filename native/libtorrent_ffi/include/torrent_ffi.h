#ifndef TORRENT_FFI_H
#define TORRENT_FFI_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
  double progress;
  int64_t download_rate;
  int64_t upload_rate;
  int64_t total_download;
  int64_t total_upload;
  int64_t total_size;
  int seeders;
  int leechers;
  int peers;
  int state;
  char error[256];
} TorrentStatusC;

typedef struct {
  int handle_id;
  TorrentStatusC status;
  char name[256];
} TorrentAlertC;

typedef void* TorrentSessionHandle;

TorrentSessionHandle torrent_session_create(const char* save_path);
void torrent_session_destroy(TorrentSessionHandle session);

int torrent_session_add_magnet(TorrentSessionHandle session, const char* magnet_uri, const char* save_path);
int torrent_session_add_torrent_file(TorrentSessionHandle session, const char* file_path, const char* save_path);

void torrent_session_remove(TorrentSessionHandle session, int handle_id);
void torrent_session_pause(TorrentSessionHandle session, int handle_id);
void torrent_session_resume(TorrentSessionHandle session, int handle_id);

int torrent_session_pop_alerts(TorrentSessionHandle session, TorrentAlertC* out_alerts, int max_alerts);
int torrent_session_get_status(TorrentSessionHandle session, int handle_id, TorrentStatusC* out_status);
int torrent_session_get_all_statuses(TorrentSessionHandle session, TorrentStatusC* out_statuses, int max_count);

void torrent_session_set_download_limit(TorrentSessionHandle session, int handle_id, int64_t limit);
void torrent_session_set_upload_limit(TorrentSessionHandle session, int handle_id, int64_t limit);

#ifdef __cplusplus
}
#endif

#endif
