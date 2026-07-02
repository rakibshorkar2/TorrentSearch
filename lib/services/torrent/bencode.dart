import 'dart:convert';
import 'dart:typed_data';

class Bencode {
  static BencodeValue parse(String input) => _parseValue(utf8.encode(input), 0).value;
  static BencodeValue parseBytes(Uint8List input) => _parseValue(input, 0).value;

  static _Result _parseValue(Uint8List data, int pos) {
    while (pos < data.length && data[pos] == 32) { pos++; }
    if (pos >= data.length) throw FormatException('Unexpected end');

    switch (data[pos]) {
      case 100: return _parseDict(data, pos);
      case 108: return _parseList(data, pos);
      case 105: return _parseInt(data, pos);
      default:  return _parseBytes(data, pos);
    }
  }

  static _Result _parseDict(Uint8List data, int pos) {
    pos++;
    final map = <String, BencodeValue>{};
    while (pos < data.length && data[pos] != 101) { // 'e'
      final keyResult = _parseBytes(data, pos);
      final key = utf8.decode(keyResult.value.bytesValue);
      pos = keyResult.nextPos;
      final valResult = _parseValue(data, pos);
      map[key] = valResult.value;
      pos = valResult.nextPos;
    }
    pos++;
    return _Result(BencodeValue(map), pos);
  }

  static _Result _parseList(Uint8List data, int pos) {
    pos++;
    final list = <BencodeValue>[];
    while (pos < data.length && data[pos] != 101) {
      final result = _parseValue(data, pos);
      list.add(result.value);
      pos = result.nextPos;
    }
    pos++;
    return _Result(BencodeValue(list), pos);
  }

  static _Result _parseInt(Uint8List data, int pos) {
    pos++;
    int end = pos;
    while (end < data.length && data[end] != 101) { end++; }
    final num = int.parse(utf8.decode(data.sublist(pos, end)));
    return _Result(BencodeValue(num), end + 1);
  }

  static _Result _parseBytes(Uint8List data, int pos) {
    int colon = pos;
    while (colon < data.length && data[colon] != 58) { colon++; }
    final len = int.parse(utf8.decode(data.sublist(pos, colon)));
    pos = colon + 1;
    final raw = data.sublist(pos, pos + len);
    return _Result(BencodeValue(raw), pos + len);
  }
}

class BencodeValue {
  final dynamic _value;
  BencodeValue(this._value);

  bool get isMap => _value is Map;
  bool get isList => _value is List;
  bool get isInt => _value is int;
  bool get isBytes => _value is Uint8List;

  Map<String, BencodeValue> get asMap => _value as Map<String, BencodeValue>;
  List<BencodeValue> get asList => _value as List<BencodeValue>;
  int get asInt => _value as int;

  String get stringValue => utf8.decode(_value as Uint8List);
  Uint8List get bytesValue => _value as Uint8List;

  BencodeValue? operator [](String key) {
    if (_value is Map) {
      return (_value as Map<String, BencodeValue>)[key];
    }
    return null;
  }

  int intValue(String key, [int fallback = 0]) {
    return this[key]?.asInt ?? fallback;
  }

  String stringValueOf(String key, [String fallback = '']) {
    final v = this[key];
    if (v == null || !v.isBytes) return fallback;
    return v.stringValue;
  }

  Uint8List rawValue(String key) {
    final v = this[key];
    if (v == null || !v.isBytes) return Uint8List(0);
    return v.bytesValue;
  }

  List<BencodeValue> listValue(String key) {
    final v = this[key];
    return v?.asList ?? [];
  }
}

class _Result {
  final BencodeValue value;
  final int nextPos;
  _Result(this.value, this.nextPos);
}
