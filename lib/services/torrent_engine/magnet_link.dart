class MagnetLink {
  final String infoHash;
  final String? displayName;
  final List<String> trackers;
  final List<String> urlList;

  MagnetLink({
    required this.infoHash,
    this.displayName,
    this.trackers = const [],
    this.urlList = const [],
  });

  String get infoHashHex => infoHash.length == 40 ? infoHash : _toHex(infoHash);

  static MagnetLink? parse(String uri) {
    if (!uri.startsWith('magnet:?')) return null;
    final query = uri.substring(8);
    final params = query.split('&');
    String? infoHash;
    String? displayName;
    final trackers = <String>[];
    final urlList = <String>[];

    for (final param in params) {
      final eq = param.indexOf('=');
      if (eq < 0) continue;
      final key = param.substring(0, eq);
      final value = Uri.decodeComponent(param.substring(eq + 1));
      switch (key) {
        case 'xt':
          if (value.startsWith('urn:btih:')) {
            infoHash = value.substring(9);
          }
        case 'dn':
          displayName = value;
        case 'tr':
          if (value.isNotEmpty) trackers.add(value);
        case 'x.ul':
          if (value.isNotEmpty) urlList.add(value);
      }
    }

    if (infoHash == null || infoHash.isEmpty) return null;
    return MagnetLink(
      infoHash: infoHash,
      displayName: displayName,
      trackers: trackers,
      urlList: urlList,
    );
  }

  static String _toHex(String raw) {
    final sb = StringBuffer();
    for (final c in raw.codeUnits) {
      sb.write(c.toRadixString(16).padLeft(2, '0'));
    }
    return sb.toString().toUpperCase();
  }
}
