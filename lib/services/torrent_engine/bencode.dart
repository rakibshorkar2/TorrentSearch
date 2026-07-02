import 'dart:convert';
import 'dart:typed_data';

class Bencode {
  final dynamic _root;

  Bencode(this._root);

  factory Bencode.parse(String source) {
    final reader = _Reader(source);
    return Bencode(reader.readValue());
  }

  factory Bencode.parseBytes(Uint8List source) {
    return Bencode.parse(utf8.decode(source));
  }

  int intValue(String key, [int fallback = 0]) {
    final map = _root;
    if (map is! Map) return fallback;
    final v = map[key];
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  String stringValueOf(String key, [String fallback = '']) {
    final map = _root;
    if (map is! Map) return fallback;
    final v = map[key];
    if (v is String) return v;
    return fallback;
  }

  List<dynamic> listValue(String key) {
    final map = _root;
    if (map is! Map) return [];
    final v = map[key];
    if (v is List) return v;
    return [];
  }

  Uint8List rawValue(String key) {
    final map = _root;
    if (map is! Map) return Uint8List(0);
    final v = map[key];
    if (v is String) return Uint8List.fromList(utf8.encode(v));
    if (v is Uint8List) return v;
    return Uint8List(0);
  }
}

class _Reader {
  final String _data;
  int _pos = 0;

  _Reader(this._data);

  dynamic readValue() {
    if (_pos >= _data.length) throw FormatException('Unexpected end of data');
    final c = _data[_pos];
    switch (c) {
      case 'i':
        return _readInt();
      case 'l':
        return _readList();
      case 'd':
        return _readDict();
      default:
        return _readString();
    }
  }

  int _readInt() {
    _pos++;
    final end = _data.indexOf('e', _pos);
    if (end < 0) throw FormatException('Unterminated integer');
    final result = int.parse(_data.substring(_pos, end));
    _pos = end + 1;
    return result;
  }

  String _readString() {
    final colon = _data.indexOf(':', _pos);
    if (colon < 0) throw FormatException('Invalid string');
    final length = int.parse(_data.substring(_pos, colon));
    _pos = colon + 1;
    final result = _data.substring(_pos, _pos + length);
    _pos += length;
    return result;
  }

  List<dynamic> _readList() {
    _pos++;
    final list = <dynamic>[];
    while (_pos < _data.length && _data[_pos] != 'e') {
      list.add(readValue());
    }
    _pos++;
    return list;
  }

  Map<String, dynamic> _readDict() {
    _pos++;
    final dict = <String, dynamic>{};
    while (_pos < _data.length && _data[_pos] != 'e') {
      final key = _readString();
      final value = readValue();
      dict[key] = value;
    }
    _pos++;
    return dict;
  }
}
